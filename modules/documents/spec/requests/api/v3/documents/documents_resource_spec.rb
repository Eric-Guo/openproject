# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 documents resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:document) { create(:document, project:) }
  let(:invisible_document) { create(:document, project: other_project) }
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_documents) }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "GET /api/v3/documents" do
    let(:path) { api_v3_paths.documents }

    before do
      document
      invisible_document

      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns a Collection of visible documents" do
      expect(subject.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(1.to_json)
        .at_path("total")

      expect(subject.body)
        .to be_json_eql("Document".to_json)
        .at_path("_embedded/elements/0/_type")

      expect(subject.body)
        .to be_json_eql(document.title.to_json)
        .at_path("_embedded/elements/0/title")
    end
  end

  describe "POST /api/v3/documents" do
    let(:path) { api_v3_paths.documents }
    let(:permissions) { %i(view_documents manage_documents) }
    let(:request_body) do
      {
        title: "New Document",
        description: { format: "markdown", raw: "Document description" },
        contentBinary: "dGVzdCBkYXRh",
        _links: { project: { href: api_v3_paths.project(project.id) } }
      }
    end

    subject(:send_request) do
      post path, request_body.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "creates a document and returns its representation" do
      expect { send_request }.to change(Document, :count).by(1)

      expect(last_response).to have_http_status(:created)

      created_document = Document.last
      expect(created_document).to have_attributes(
        title: "New Document",
        description: "Document description",
        content_binary: "dGVzdCBkYXRh",
        project:
      )
      expect(last_response.body).to be_json_eql("Document".to_json).at_path("_type")
      expect(last_response.body).to be_json_eql(created_document.id.to_json).at_path("id")
      expect(last_response.body).to be_json_eql(created_document.title.to_json).at_path("title")
      expect(last_response.body).to be_json_eql(created_document.description.to_json).at_path("description/raw")
      expect(last_response.body).to be_json_eql(created_document.content_binary.to_json).at_path("contentBinary")
      expect(last_response.body).to be_json_eql(api_v3_paths.document(created_document.id).to_json).at_path("_links/self/href")
      expect(last_response.body).to be_json_eql(api_v3_paths.project(project.id).to_json).at_path("_links/project/href")
    end

    context "with only the required attributes" do
      let(:request_body) do
        {
          title: "New Document",
          _links: { project: { href: api_v3_paths.project(project.id) } }
        }
      end

      it "creates a document" do
        expect { send_request }.to change(Document, :count).by(1)
        expect(last_response).to have_http_status(:created)
        expect(last_response.body).to match_json_schema.from_docs("document_model")
      end
    end

    context "when lacking manage permissions" do
      let(:permissions) { %i(view_documents) }

      it "returns 403 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "when the project belongs to another user" do
      let(:request_body) do
        super().deep_merge(_links: { project: { href: api_v3_paths.project(other_project.id) } })
      end

      it "returns 403 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "when the documents module is disabled" do
      before do
        project.enabled_module_names = []
      end

      it "returns 403 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "with a blank title" do
      let(:request_body) { super().merge(title: "") }

      it "returns the validation error and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(last_response.body).to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
          .at_path("errorIdentifier")
        expect(last_response.body).to be_json_eql("title".to_json).at_path("_embedded/details/attribute")
      end
    end

    context "with a title longer than 255 characters" do
      let(:request_body) { super().merge(title: "a" * 256) }

      it "returns 422 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without a project" do
      let(:request_body) { super().except(:_links) }

      it "returns 403 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "with a nonexistent project" do
      let(:request_body) do
        super().deep_merge(_links: { project: { href: api_v3_paths.project(0) } })
      end

      it "returns 403 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:forbidden)
      end
    end

    context "when not logged in" do
      let(:current_user) { User.anonymous }

      it "returns 401 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:unauthorized)
      end
    end

    context "with an invalid project link" do
      let(:request_body) do
        super().deep_merge(_links: { project: { href: api_v3_paths.user(current_user.id) } })
      end

      it "returns 422 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with malformed JSON" do
      subject(:send_request) do
        post path, "{", "CONTENT_TYPE" => "application/json"
      end

      it "returns 400 and does not create a document" do
        expect { send_request }.not_to change(Document, :count)
        expect(last_response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /api/v3/documents/:id" do
    let(:path) { api_v3_paths.document(document.id) }

    before do
      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the document" do
      expect(subject.body)
        .to be_json_eql("Document".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(document.id.to_json)
        .at_path("id")
    end

    context "when the document has content_binary" do
      before do
        document.update!(content_binary: "base64string")

        get path
      end

      it "includes content_binary field" do
        expect(subject.body)
          .to be_json_eql(document.content_binary.to_json)
          .at_path("contentBinary")
      end
    end

    context "when lacking permissions" do
      let(:permissions) { [] }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end

  describe "PATCH /api/v3/documents/:id" do
    let(:path) { api_v3_paths.document(document.id) }
    let(:permissions) { %i(view_documents manage_documents) }
    let(:request_body) do
      {
        title: "Updated Document Title",
        content_binary: "dGVzdCBkYXRh" # base64 encoded "test data"
      }
    end

    before do
      patch path, request_body.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "returns 200 OK" do
      expect(subject.status).to be(200)
    end

    it "updates the document and returns updated document" do
      expect(subject.body)
        .to be_json_eql("Document".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql("Updated Document Title".to_json)
        .at_path("title")

      expect(subject.body)
        .to be_json_eql("dGVzdCBkYXRh".to_json)
        .at_path("contentBinary")
    end

    context "when lacking edit permissions" do
      let(:permissions) { %i(view_documents) }

      it "returns 403 FORBIDDEN" do
        expect(subject.status)
          .to be(403)
      end

      context "when trying to move document to another project where user can manage documents" do
        let(:target_project) { create(:project) }
        let(:target_role) { create(:project_role, permissions: %i(view_documents manage_documents)) }
        let(:request_body) do
          {
            project_id: target_project.id,
            title: "Moved Document Title"
          }
        end

        before do
          create(:member, principal: current_user, project: target_project, roles: [target_role])
          document # ensure the source document exists before patching
        end

        it "returns 403 FORBIDDEN" do
          expect(subject.status).to be(403)
        end

        it "does not move the document to another project" do
          expect(document.reload.project_id).to eq(project.id)
        end
      end
    end

    context "when lacking view permissions" do
      let(:permissions) { [] }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end
end

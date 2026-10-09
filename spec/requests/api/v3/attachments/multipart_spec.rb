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

RSpec.describe "API v3 multipart attachment uploads" do
  include Rack::Test::Methods
  include FileHelpers

  shared_let(:project) { create(:project) }
  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  let(:metadata) { { fileName: "stored.txt", description: { format: "plain", raw: "**plain** description" } } }
  let(:file) { mock_uploaded_file(name: "original.txt", content: "upload content") }
  let(:request_parts) { { metadata: metadata.to_json, file: } }

  before do
    login_as(current_user)
  end

  shared_examples "a multipart upload" do
    subject(:upload) { post path, request_parts }

    it "stores the file using the metadata name and plain description" do
      upload

      expect(last_response).to have_http_status(:created)
      expect(JSON.parse(last_response.body)).to include(
        "fileName" => "stored.txt",
        "status" => "uploaded",
        "description" => include("format" => "plain", "raw" => "**plain** description")
      )
      expect(Attachment.find(JSON.parse(last_response.body)["id"]).file.read).to eq("upload content")
    end

    it "accepts an application/json metadata part without a filename" do
      body = [
        "--boundary",
        'Content-Disposition: form-data; name="metadata"',
        "Content-Type: application/json",
        "",
        metadata.to_json,
        "--boundary",
        'Content-Disposition: form-data; name="file"; filename="original.txt"',
        "Content-Type: text/plain",
        "",
        "upload content",
        "--boundary--",
        ""
      ].join("\r\n")

      post path, body, "CONTENT_TYPE" => "multipart/form-data; boundary=boundary"

      expect(last_response).to have_http_status(:created)
      expect(JSON.parse(last_response.body)).to include("fileName" => "stored.txt")
      expect(Attachment.find(JSON.parse(last_response.body)["id"]).file.read).to eq("upload content")
    end

    context "with content metadata but no file" do
      let(:metadata) { { fileName: "stored.txt", contentType: "text/plain", fileSize: 42 } }
      let(:request_parts) { { metadata: metadata.to_json, other: file } }

      it "rejects the upload without creating an attachment" do
        expect { upload }.not_to change(Attachment, :count)
        expect(last_response).to have_http_status(:unprocessable_entity)
      end
    end

    shared_examples "an invalid property" do |attribute|
      it "returns a property format error without creating an attachment" do
        expect { upload }.not_to change(Attachment, :count)
        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(last_response.body)).to include(
          "errorIdentifier" => "urn:openproject-org:api:v3:errors:PropertyFormatError",
          "_embedded" => include("details" => include("attribute" => attribute))
        )
      end
    end

    [nil, [], "text", false, 123].each do |value|
      context "with #{value.inspect} metadata" do
        let(:metadata) { value }

        it_behaves_like "an invalid property", "metadata"
      end
    end

    context "with metadata sent as a file" do
      let(:request_parts) do
        { metadata: mock_uploaded_file(name: "metadata.json", content: metadata.to_json,
                                       content_type: "application/json"), file: }
      end

      it_behaves_like "an invalid property", "metadata"
    end

    context "with metadata split into form fields" do
      let(:request_parts) { { "metadata[fileName]" => "stored.txt", file: } }

      it_behaves_like "an invalid property", "metadata"
    end

    [123, {}, [], false].each do |value|
      context "with #{value.inspect} fileName" do
        let(:metadata) { { fileName: value } }

        it_behaves_like "an invalid property", "fileName"
      end
    end

    [nil, false, [], "text"].each do |value|
      context "with #{value.inspect} description" do
        let(:metadata) { { fileName: "stored.txt", description: value } }

        it_behaves_like "an invalid property", "description"
      end
    end

    context "with a non-string description raw value" do
      let(:metadata) { { fileName: "stored.txt", description: { raw: [] } } }

      it_behaves_like "an invalid property", "description.raw"
    end

    context "with file content sent without a filename" do
      let(:request_parts) { { metadata: metadata.to_json, file: "content", other: file } }

      it_behaves_like "an invalid property", "file"
    end

    context "with file split into form fields" do
      let(:request_parts) do
        { metadata: metadata.to_json, "file[tempfile]" => "content", "file[type]" => "text/plain", other: file }
      end

      it_behaves_like "an invalid property", "file"
    end
  end

  context "without a container" do
    let(:path) { "/api/v3/attachments" }

    it_behaves_like "a multipart upload"
  end

  context "with a work package container" do
    let(:path) { "/api/v3/work_packages/#{work_package.id}/attachments" }

    it_behaves_like "a multipart upload"
  end

  context "with direct uploads", :with_direct_uploads do
    it "prepares an upload with metadata and no file part" do
      metadata = { fileName: "stored.txt", contentType: "text/plain", fileSize: 42 }
      body = [
        "--boundary",
        'Content-Disposition: form-data; name="metadata"',
        "Content-Type: application/json",
        "",
        metadata.to_json,
        "--boundary--",
        ""
      ].join("\r\n")

      post "/api/v3/attachments/prepare", body, "CONTENT_TYPE" => "multipart/form-data; boundary=boundary"

      expect(last_response).to have_http_status(:created)
      expect(JSON.parse(last_response.body)).to include("_type" => "AttachmentUpload", "fileName" => "stored.txt")
    end
  end
end

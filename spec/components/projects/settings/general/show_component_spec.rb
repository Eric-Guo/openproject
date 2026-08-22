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

require "rails_helper"

RSpec.describe Projects::Settings::General::ShowComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  def render_component(**params)
    render_inline(described_class.new(project:, current_user:, **params))
    page
  end

  shared_examples "section with heading" do |heading|
    it "has section semantics" do
      expect(render_component).to have_section(heading)
    end

    it "renders a heading" do
      expect(render_component).to have_heading(heading)
    end

    it "renders a form" do
      render_component

      expect(page.find(:section, heading)).to have_element :form
    end
  end

  describe "Basic details" do
    it_behaves_like "section with heading", "Basic details"

    it "renders fields" do
      expect(render_component).to have_field Project.human_attribute_name(:name), required: true
      expect(render_component).to have_element "opce-ckeditor-augmented-textarea",
                                               "data-test-selector": "augmented-text-area-description"
    end

    context "with the TH projects module enabled" do
      let(:project) do
        build_stubbed(:project, enabled_module_names: %w[th_projects]).tap do |project|
          allow(project)
            .to receive(:profile)
            .and_return(ProjectProfile.new(type_id: 2,
                                           name: "TH Project",
                                           code: "TH12345",
                                           doc_link: "https://example.com/doc"))
        end
      end

      it "renders project profile fields" do
        render_component

        expect(page).to have_select ProjectProfile.human_attribute_name(:type_id),
                                    selected: I18n.t("activerecord.attributes.project_profile.type_id_list.2")
        expect(page).to have_field ProjectProfile.human_attribute_name(:name), with: "TH Project"
        expect(page).to have_field ProjectProfile.human_attribute_name(:code), with: "TH12345"
        expect(page).to have_field ProjectProfile.human_attribute_name(:doc_link),
                                   with: "https://example.com/doc",
                                   disabled: true
        expect(page).to have_select nil, name: "project[profile_attributes][type_id]"
        expect(page).to have_field nil, name: "project[profile_attributes][name]"
        expect(page).to have_field nil, name: "project[profile_attributes][code]"
        expect(page).to have_field nil, name: "project[profile_attributes][doc_link]", disabled: true
      end

      context "when the user is a global admin" do
        let(:user) { build_stubbed(:admin) }

        it "enables the project document link field" do
          expect(render_component).to have_field ProjectProfile.human_attribute_name(:doc_link),
                                                 with: "https://example.com/doc",
                                                 disabled: false
        end
      end
    end
  end

  describe "Status" do
    it_behaves_like "section with heading", "Status"

    it "renders field" do
      expect(render_component).to have_element "opce-ckeditor-augmented-textarea",
                                               "data-test-selector": "augmented-text-area-status_explanation"
    end
  end

  describe "Identifier" do
    it_behaves_like "section with heading", "Identifier"

    it "renders a Change identifier button" do
      render_component
      expect(page.find(:section, I18n.t("projects.settings.header_identifier")))
        .to have_link I18n.t("projects.settings.change_identifier")
    end
  end

  describe "Project relations" do
    it_behaves_like "section with heading", "Project relations"

    it "renders field" do
      expect(render_component).to have_element "opce-project-autocompleter",
                                               "data-input-name": "\"project[parent_id]\""
    end
  end
end

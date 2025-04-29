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

RSpec.describe "Projects", "editing settings", :js do
  let(:name_field) { FormFields::InputFormField.new :name }
  let(:parent_field) { FormFields::SelectFormField.new :parent }
  let(:permissions) { %i(edit_project view_project_attributes edit_project_attributes) }

  current_user do
    create(:user, member_with_permissions: { project => permissions })
  end

  shared_let(:project) do
    create(:project, name: "Foo project", identifier: "foo-project")
  end

  it "hides the field whose functionality is presented otherwise" do
    visit project_settings_general_path(project.id)

    expect(page).to have_no_text :all, "Active"
    expect(page).to have_no_text :all, "Identifier"
  end

  describe "identifier edit" do
    it "updates the project identifier" do
      visit projects_path
      click_on project.name
      click_on "Project settings"
      click_on "Change identifier"

      expect(page).to have_content "Change the project's identifier".upcase
      expect(page).to have_current_path "/projects/foo-project/identifier"

      fill_in "project[identifier]", with: "foo-bar"
      click_on "Update"

      expect(page).to have_content "Successful update."
      expect(page)
        .to have_current_path %r{/projects/foo-bar/settings/general}
      expect(Project.first.identifier).to eq "foo-bar"
    end

    it "displays error messages on invalid input" do
      visit project_identifier_path(project)

      fill_in "project[identifier]", with: "FOOO"
      click_on "Update"

      expect(page).to have_content "Identifier is invalid."
      expect(page).to have_current_path "/projects/foo-project/identifier"
    end
  end

  context "with optional and required custom fields" do
    let!(:optional_custom_field) do
      create(:project_custom_field, name: "Optional Foo",
                                    is_for_all: true,
                                    projects: [project])
    end
    let!(:required_custom_field) do
      create(:project_custom_field, name: "Required Foo",
                                    is_for_all: true,
                                    is_required: true,
                                    projects: [project])
    end

    it "shows optional and required custom fields for edit without a separation" do
      project.custom_field_values.last.value = "FOO"
      project.save!

      visit project_settings_general_path(project.id)

      expect(page).to have_text "Optional Foo"
      expect(page).to have_text "Required Foo"
    end
  end

  context "with a length internal custom field" do
    let!(:required_custom_field) do
      create(:string_project_custom_field,
             name: "Foo",
             min_length: 1,
             max_length: 2,
             is_for_all: true,
             projects: [project])
    end
    let(:foo_field) { FormFields::InputFormField.new required_custom_field }

    it "shows the errors of that field when saving (Regression #33766)" do
      visit project_settings_general_path(project.id)

      expect(page).to have_content "Foo"

      # Enter something too long
      foo_field.set_value "1234"

      # It should cut of that remaining value
      foo_field.expect_value "12"

      click_button "Save"

      expect(page).to have_text "Successful update."
    end
  end

  context "with a multi-select list custom field" do
    include_context "ng-select-autocomplete helpers"

    let!(:list_custom_field) { create(:list_project_custom_field, name: "List CF", multi_value: true, projects: [project]) }
    let(:form_field) { FormFields::SelectFormField.new list_custom_field }

    it "can select multiple values" do
      visit project_settings_general_path(project.id)

      form_field.select_option "A", "B"

      click_on "Save"

      expect(page).to have_content "Successful update."

      form_field.expect_selected "A", "B"

      cvs = project.reload.custom_value_for(list_custom_field)
      expect(cvs.count).to eq 2
      expect(cvs.map(&:typed_value)).to contain_exactly "A", "B"
    end
  end

  context "with a multi-select user custom field" do
    include_context "ng-select-autocomplete helpers"

    let!(:list_custom_field) { create(:user_project_custom_field, name: "List CF", multi_value: true, projects: [project]) }
    let(:dummy_role) { create(:project_role) }
    let!(:users) do
      [
        create(:user, firstname: "First", lastname: "User", member_with_roles: { project => [dummy_role] }),
        create(:user, firstname: "Second", lastname: "User", member_with_roles: { project => [dummy_role] }),
        create(:user, firstname: "Third", lastname: "User", member_with_roles: { project => [dummy_role] })
      ]
    end
    let(:form_field) { FormFields::SelectFormField.new list_custom_field }

    it "can select multiple values" do
      visit project_settings_general_path(project.id)

      form_field.select_option users.first.name, users.last.name

      click_on "Save"

      expect(page).to have_content "Successful update."

      refresh

      expect(page).to have_no_content "Successful update."

      form_field.expect_selected users.first.name, users.last.name
    end
  end

  context "with a version custom field" do
    include_context "ng-select-autocomplete helpers"

    shared_let(:public_project) do
      create(:project, name: "Public Pr", identifier: "public-pr", public: true)
    end

    let!(:versions) do
      [
        create(:version, project:, name: "Ringbo 1.0", sharing: "system"),
        create(:version, project: public_project, name: "Ringbo 2.0", sharing: "system")
      ]
    end

    let!(:version_custom_field) do
      create(:version_project_custom_field,
             name: "List CF",
             multi_value: true,
             projects: [project])
    end

    let(:form_field) { FormFields::SelectFormField.new version_custom_field }

    it "can select multiple values" do
      visit project_settings_general_path(project.id)

      # expect the versions are grouped by the project name
      form_field.expect_option(versions.first.name, grouping: project.name)
      form_field.expect_option(versions.last.name, grouping: public_project.name)

      form_field.select_option(versions.first.name, versions.last.name)

      click_on "Save"

      expect(page).to have_content "Successful update."

      refresh

      expect(page).to have_no_content "Successful update."

      form_field.expect_selected versions.first.name, versions.last.name
    end
  end

  context "with a date custom field" do
    let!(:date_custom_field) { create(:date_project_custom_field, name: "Date", projects: [project]) }
    let(:form_field) { FormFields::InputFormField.new date_custom_field }

    it "can save and remove the date (Regression #37459)" do
      visit project_settings_general_path(project.id)

      form_field.set_value "2021-05-26"
      form_field.send_keys :enter

      click_on "Save"

      expect(page).to have_content "Successful update."

      form_field.expect_value "2021-05-26"

      cv = project.reload.custom_value_for(date_custom_field)
      expect(cv.typed_value).to eq "2021-05-26".to_date
    end
  end

  context "with a user not allowed to see the parent project" do
    include_context "ng-select-autocomplete helpers"

    let(:parent_project) { create(:project) }
    let(:parent_field) { FormFields::SelectFormField.new "parent" }

    before do
      project.update_attribute(:parent, parent_project)
    end

    it "can update the project without destroying the relation to the parent" do
      visit project_settings_general_path(project.id)

      fill_in "Name", with: "New project name"

      parent_field.expect_selected I18n.t(:"api_v3.undisclosed.parent")

      click_on "Save"

      expect(page).to have_content "Successful update."

      project.reload

      expect(project.name)
        .to eql "New project name"

      expect(project.parent)
        .to eql parent_project
    end
  end

  context "with correct scoping of project custom fields" do
    let!(:optional_custom_field_activated_in_project) do
      create(:project_custom_field, name: "Optional Foo",
                                    is_for_all: true,
                                    projects: [project])
    end
    let!(:optional_custom_field_not_activated_in_project) do
      create(:project_custom_field, name: "Optional Bar",
                                    is_for_all: true)
    end

    it "shows only the custom fields that are activated in the project" do
      visit project_settings_general_path(project.id)

      expect(page).to have_text "Optional Foo"
      expect(page).to have_no_text "Optional Bar"
    end
  end

  describe "permissions" do
    context "with edit_project permission only" do
      let!(:custom_field) { create(:string_project_custom_field, projects: [project]) }
      let(:foo_field) { FormFields::InputFormField.new custom_field }
      let(:role) { Role.first }

      it "does not show custom fields" do
        role.update(permissions: permissions - %i(edit_project_attributes))

        visit project_settings_general_path(project)
        expect(page).to have_no_content(custom_field.name)
      end

      it "does not allow saving custom fields" do
        visit project_settings_general_path(project.id)

        expect(page).to have_content(custom_field.name)

        # Remove edit_project_attributes after loading the form
        role.update(permissions: permissions - %i(edit_project_attributes))
        current_user.reload

        foo_field.set_value "1234"

        click_on "Save"
        expect(page)
          .to have_text "#{custom_field.name} was attempted to be written but is not writable."
      end
    end
  end

  describe "attribute help texts", :selenium do
    let(:general_page) { Pages::Projects::Settings::General.new(project) }

    context "without attribute help texts defined" do
      before do
        general_page.visit!
      end

      it "shows field labels without help text link" do
        general_page.expect_field_label_without_help_text "Name"
        general_page.expect_field_label_without_help_text "Description"
        general_page.expect_field_label_without_help_text "Project status description"
        general_page.expect_field_label_without_help_text "Subproject of"
      end

      it "does not show help text link next to status button" do
        within_section "Project status" do
          button = find_button("Edit project status")
          expect(page).to have_no_link accessible_name: "Show help text", right_of: button
        end
      end
    end

    context "with attribute help texts defined" do
      let!(:name_help_text) { create(:project_help_text, attribute_name: :name) }
      let!(:description_help_text) { create(:project_help_text, attribute_name: :description) }
      let!(:status_help_text) { create(:project_help_text, attribute_name: :status) }
      let!(:status_description_help_text) { create(:project_help_text, attribute_name: :status_explanation) }
      let!(:subproject_of_help_text) { create(:project_help_text, attribute_name: :parent) }

      before do
        general_page.visit!
      end

      it "shows field labels with help text link" do
        general_page.expect_field_label_with_help_text "Name"
        general_page.expect_field_label_with_help_text "Description"
        general_page.expect_field_label_with_help_text "Project status description"
        general_page.expect_field_label_with_help_text "Subproject of"
      end

      it "shows help text link next to status button" do
        within_section "Project status" do
          button = find_button("Edit project status")
          expect(page).to have_link accessible_name: "Show help text", right_of: button
        end
      end

      it "shows help text modal on clicking help text link" do
        general_page.click_help_text_link_for_label "Description"

        expect(page).to have_modal "Description"
        within_modal "Description" do
          expect(page).to have_text "Attribute help text"

          click_on "Close"
        end
        expect(page).to have_no_modal "Description"
      end
    end
  end
end

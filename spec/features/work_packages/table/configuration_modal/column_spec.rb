# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work Package table configuration modal columns spec", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let!(:wp_1) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }
  let!(:work_package) { create(:work_package, project:) }

  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = %w[id subject]

    query.save!
    query
  end

  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
    expect(page).to have_css(".wp-table--table-header", text: "ID")
    expect(page).to have_css(".wp-table--table-header", text: "SUBJECT")
  end

  shared_examples "add and remove columns" do
    it do
      columns.open_modal
      columns.expect_checked "ID"
      columns.expect_checked "Subject"

      columns.remove "Subject", save_changes: false
      columns.add "Project", save_changes: true
      columns.expect_column_available "Subject"
      columns.expect_column_not_available /Project\z/

      expect(page).to have_css(".wp-table--table-header", text: "ID")
      expect(page).to have_css(".wp-table--table-header", text: "PROJECT")
      expect(page).to have_no_css(".wp-table--table-header", text: "SUBJECT")
    end
  end

  context "When seeing the table" do
    it_behaves_like "add and remove columns"

    context "with three columns", driver: :firefox_de do
      let!(:query) do
        query = build(:query, user:, project:)
        query.column_names = %w[id project subject]

        query.save!
        query
      end

      it "can reorder columns" do
        columns.open_modal
        columns.expect_checked "ID"
        columns.expect_checked "Project"
        columns.expect_checked "Subject"

        # Drag subject left of project
        subject_column = columns.column_item("Subject")
        project_column = columns.column_item("Project")

        scroll_to_element(subject_column)
        subject_column.hover

        page
          .driver
          .browser
          .action
          .move_to(subject_column.native)
          .click_and_hold(subject_column.native)
          .perform

        page.all(".op-draggable-autocomplete--item").each do |item|
          next if item == subject_column

          page
            .driver
            .browser
            .action
            .move_to(item.native)
            .perform
        end

        page
          .driver
          .browser
          .action
          .move_to(project_column.native)
          .release
          .perform

        within ".op-draggable-autocomplete--selected" do
          expect(page).to have_css(".op-draggable-autocomplete--item:nth-child(2) .op-draggable-autocomplete--item-text",
                                   text: "Subject")
        end

        columns.apply

        expect(page).to have_css(".wp-table--table-header a", count: 3)

        header_names = page.all(".wp-table--table-header a").map { |element| element.text.downcase }

        expect(header_names).to eq(%w[id subject project])
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package integration tabs refreshing", :js do
  let(:project) do
    create(:project_with_types,
           enabled_module_names: %i[work_package_tracking github gitlab])
  end
  let!(:work_package) { create(:work_package, project:) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:user) { create(:admin) }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it "hides integration tabs disabled while the work package list remains open" do
    project.enabled_modules.where(name: %w[github gitlab]).destroy_all

    split_view = wp_table.open_split_view(work_package)
    split_view.expect_open

    split_view.expect_no_tab("Github")
    split_view.expect_no_tab("Gitlab")
  end

  it "hides integration tabs disabled before opening the full view" do
    project.enabled_modules.where(name: %w[github gitlab]).destroy_all

    full_view = wp_table.open_full_screen_by_link(work_package)

    full_view.expect_no_tab("Github")
    full_view.expect_no_tab("Gitlab")
  end
end

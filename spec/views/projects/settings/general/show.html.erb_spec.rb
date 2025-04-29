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

RSpec.describe "projects/settings/general/show" do
  include TestSelectorFinders

  let(:project) { build_stubbed(:project, public:) }
  let(:user) { build_stubbed(:admin) }

  before do
    assign(:project, project)

    without_partial_double_verification do
      allow(view)
        .to receive(:current_user)
        .and_return(user)
    end

    render
  end

  context "when project is not public" do
    let(:public) { false }

    it "does not show warning banner" do
      expect(rendered).not_to have_test_selector "op-projects-public-warning"
    end
  end

  context "when project is public" do
    let(:public) { true }

    before do
      assign(:project, project)
      allow(project).to receive(:copy_allowed?).and_return(true)
      allow(User).to receive(:current).and_return(admin)
      allow(view).to receive(:labelled_tabular_form_for).and_return("")
      render
    end

    it "show delete and archive buttons" do
      expect(rendered).to have_test_selector "project-settings--archive"
      expect(rendered).to have_test_selector "project-settings--delete"
    end
  end

  context "User.current is non-admin" do
    let(:non_admin) { build_stubbed(:user) }

    before do
      assign(:project, project)
      allow(project).to receive(:copy_allowed?).and_return(true)
      allow(User).to receive(:current).and_return(non_admin)
      allow(view).to receive(:labelled_tabular_form_for).and_return("")
      render
    end

    it "hide delete and archive buttons" do
      expect(rendered).to have_no_css("li.toolbar-item span.button--text", text: "Archive project")
      expect(rendered).to have_no_css("li.toolbar-item span.button--text", text: "Delete project")
    end
  end
end

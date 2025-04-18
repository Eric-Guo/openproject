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

RSpec.describe My::TimeTracking::TimeEntryRow, type: :component do
  let(:project) { create(:project_with_types) }
  let(:work_package) { create(:work_package, project:) }
  let(:user) do
    create(:user, member_with_permissions: { project => %i[view_project edit_own_time_entries] })
  end
  let(:table) { instance_double(My::TimeTracking::TimeEntriesListComponent) }

  before do
    allow(table).to receive(:columns).and_return([])
  end

  subject(:row_component) { described_class.new(row: time_entry, table:) }

  context "when the time entry is older than 9 days" do
    let(:time_entry) { create(:time_entry, user:, entity: work_package, spent_on: Date.current - 9.days) }

    current_user { user }

    around do |example|
      travel_to Date.new(2026, 4, 18) do
        example.run
      end
    end

    it "does not expose row actions" do
      expect(row_component.action_menu).to be_nil
    end
  end

  context "when the time entry is approved" do
    let(:time_entry) { create(:time_entry, user:, entity: work_package, approved_by: create(:admin)) }

    current_user { user }

    it "does not expose row actions" do
      expect(row_component.action_menu).to be_nil
    end
  end
end

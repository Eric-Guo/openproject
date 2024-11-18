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

RSpec.describe Type do
  let(:type) { build(:type) }
  let(:type2) { build(:type) }
  let(:project) { build(:project, no_types: true) }

  describe ".enabled_in(project)" do
    before do
      type.projects << project
      type.save

      type2.save
    end

    it "returns the types enabled in the provided project" do
      expect(described_class.enabled_in(project)).to contain_exactly(type)
    end
  end

  describe ".visible" do
    subject { described_class.visible(user) }

    let!(:type) { create(:type) }
    let!(:admin_only_type) { create(:type, is_admin_only: true) }
    let(:user) { create(:user) }
    let(:permissions) { %i[view_work_packages] }

    before do
      create(:member, user:, roles: [create(:project_role, permissions: permissions)])
    end

    it "returns all non-admin-only types" do
      expect(subject.to_a).to match_array(described_class.where(is_admin_only: false).to_a)
    end

    context "when the user has the manage_types permission in a project" do
      let(:permissions) { %i[manage_types] }

      it "returns all non-admin-only types" do
        expect(subject.to_a).to match_array(described_class.where(is_admin_only: false).to_a)
      end
    end

    context "when the user is an admin" do
      let(:user) { create(:admin) }

      it "returns all types" do
        expect(subject.to_a).to match_array(described_class.all.to_a)
      end
    end

    context "when the user has the wrong permission" do
      let(:permissions) { %i[view_wikis] }

      it "returns no types" do
        expect(subject.to_a).to be_empty
      end
    end
  end

  describe "#statuses" do
    subject { type.statuses }

    context "when new" do
      let(:type) { build(:type) }

      it "returns an empty relation" do
        expect(subject).to be_empty
      end
    end

    context "when existing but no statuses" do
      let(:type) { create(:type) }

      it "returns an empty relation" do
        expect(subject).to be_empty
      end
    end

    context "when existing with workflow" do
      let(:role) { create(:project_role) }
      let(:statuses) { (1..2).map { |_i| create(:status) } }

      let!(:type) { create(:type) }
      let!(:workflow_a) do
        create(:workflow, role_id: role.id,
                          type_id: type.id,
                          old_status_id: statuses[0].id,
                          new_status_id: statuses[1].id,
                          author: false,
                          assignee: false)
      end

      it "returns the statuses relation" do
        expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
      end

      context "with default status" do
        let!(:default_status) { create(:default_status) }

        subject { type.statuses(include_default: true) }

        it "returns the workflow and the default status" do
          expect(subject.pluck(:id)).to contain_exactly(default_status.id, statuses[0].id, statuses[1].id)
        end
      end

      context "with role filter" do
        let(:other_role) { create(:project_role) }
        let(:other_statuses) { (1..2).map { create(:status) } }
        let!(:other_workflow) do
          create(:workflow, role_id: other_role.id,
                            type_id: type.id,
                            old_status_id: other_statuses[0].id,
                            new_status_id: other_statuses[1].id)
        end

        subject { type.statuses(role:) }

        it "returns only statuses for the given role" do
          expect(subject.pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end
      end

      context "with tab filter" do
        let(:author_statuses) { (1..2).map { create(:status) } }
        let(:assignee_statuses) { (1..2).map { create(:status) } }
        let!(:author_workflow) do
          create(:workflow, role_id: role.id,
                            type_id: type.id,
                            old_status_id: author_statuses[0].id,
                            new_status_id: author_statuses[1].id,
                            author: true,
                            assignee: false)
        end
        let!(:assignee_workflow) do
          create(:workflow, role_id: role.id,
                            type_id: type.id,
                            old_status_id: assignee_statuses[0].id,
                            new_status_id: assignee_statuses[1].id,
                            author: false,
                            assignee: true)
        end

        it "returns only always statuses for the always tab" do
          expect(type.statuses(tab: "always").pluck(:id)).to contain_exactly(statuses[0].id, statuses[1].id)
        end

        it "returns only author statuses for the author tab" do
          expect(type.statuses(tab: "author").pluck(:id)).to contain_exactly(author_statuses[0].id, author_statuses[1].id)
        end

        it "returns only assignee statuses for the assignee tab" do
          expect(type.statuses(tab: "assignee").pluck(:id)).to contain_exactly(assignee_statuses[0].id, assignee_statuses[1].id)
        end
      end
    end
  end

  describe "#copy_from_type on workflows" do
    before do
      allow(Workflow)
        .to receive(:copy)
    end

    it "calls the .copy method on Workflow" do
      type.workflows.copy_from_type(type2)

      expect(Workflow)
        .to have_received(:copy)
        .with(type2, nil, type, nil)
    end
  end

  describe "#work_package_attributes" do
    subject { type.work_package_attributes }

    context "for the duration field" do
      it "does not return the field" do
        expect(subject).not_to have_key("duration")
      end
    end

    context "for the ignore_non_working_days field" do
      it "does not return the field" do
        expect(subject).not_to have_key("ignore_non_working_days")
      end
    end
  end

  describe "#patterns" do
    it "returns an empty collection when no patterns are defined" do
      type = create(:type)

      expect(type.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
    end

    it "returns a PatternCollection" do
      type = create(:type, patterns: {
                      subject: { blueprint: "{{work_package:custom_field_123}} - {{project:custom_field_321}}", enabled: true }
                    })

      expect(type.patterns).to be_a(WorkPackageTypes::Patterns::Collection)
      expect(type.patterns.subject)
        .to eq(WorkPackageTypes::Pattern.new("{{work_package:custom_field_123}} - {{project:custom_field_321}}", true))
    end
  end

  describe "#patterns=" do
    subject(:type) { build(:type) }

    it "assigns a patterns collection as-is" do
      collection = WorkPackageTypes::Patterns::Collection.build(patterns: {
                                                       subject: { blueprint: "some_string", enabled: false }
                                                     }).value!

      type.patterns = collection

      expect(type.patterns).to eq(collection)
      expect { type.save! }.not_to raise_error
    end

    context "when an invalid value is passed" do
      it "defaults to an empty collection" do
        type.patterns = 4

        expect(type.patterns).to eq(WorkPackageTypes::Patterns::Collection.empty)
        expect { type.save! }.not_to raise_error
      end
    end

    context "when a hash is passed" do
      it "converts the incoming hash into a PatternCollection" do
        type.patterns = { subject: { blueprint: "some_string", enabled: false } }

        expect(type.patterns).to be_a(WorkPackageTypes::Patterns::Collection)
        expect(type.patterns.subject).to be_a(WorkPackageTypes::Pattern)

        expect { type.save! }.not_to raise_error
      end
    end
  end
end

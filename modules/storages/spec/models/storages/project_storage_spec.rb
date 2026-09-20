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
require_module_spec_helper

module Storages
  RSpec.describe ProjectStorage do
    let(:creator) { create(:user) }
    let(:project) { create(:project, enabled_module_names: %i[storages work_packages]) }
    let(:storage) { create(:nextcloud_storage) }
    let(:attributes) do
      { storage:, creator:, project:, project_folder_mode: :inactive }
    end

    describe "#create" do
      it "creates an instance" do
        project_storage = described_class.create attributes
        expect(project_storage).to be_valid
      end

      context "when having already one instance" do
        let(:old_project_storage) { described_class.create attributes }

        before do
          old_project_storage
        end

        it "fails if it is not unique per storage and project" do
          expect(described_class.create(attributes.merge)).not_to be_valid
        end
      end
    end

    describe "#destroy" do
      let(:project_storage_to_destroy) { described_class.create(attributes) }
      let(:work_package) { create(:work_package, project:) }
      let(:file_link) { create(:file_link, storage:, container_id: work_package.id) }

      before do
        project_storage_to_destroy
        file_link

        project_storage_to_destroy.destroy
      end

      it "does not destroy associated FileLink records" do
        expect(described_class.count).to eq 0
        expect(FileLink.count).not_to eq 0
      end
    end

    describe "#project_folder_mode_possible?" do
      let(:project_storage) { build_stubbed(:project_storage, storage:) }

      context "when the storage is automatically managed" do
        context "when the storage is a one drive storage" do
          let(:storage) { build_stubbed(:one_drive_storage, :as_automatically_managed) }

          it "returns true for project_folder_mode inactive" do
            expect(project_storage.project_folder_mode_possible?("inactive")).to be true
          end

          it "returns true for project_folder_mode automatic" do
            expect(project_storage.project_folder_mode_possible?("automatic")).to be true
          end

          it "returns false for project_folder_mode manual" do
            expect(project_storage.project_folder_mode_possible?("manual")).to be false
          end
        end

        context "when the storage is a nextcloud storage" do
          let(:storage) { build_stubbed(:nextcloud_storage, :as_automatically_managed) }

          it "returns true for project_folder_mode inactive" do
            expect(project_storage.project_folder_mode_possible?("inactive")).to be true
          end

          it "returns true for project_folder_mode automatic" do
            expect(project_storage.project_folder_mode_possible?("automatic")).to be true
          end

          it "returns true for project_folder_mode manual" do
            expect(project_storage.project_folder_mode_possible?("manual")).to be true
          end
        end
      end

      context "when the storage is not automatically managed" do
        context "when the storage is a one drive storage" do
          let(:storage) { build_stubbed(:one_drive_storage, :as_not_automatically_managed) }

          it "returns true for project_folder_mode inactive" do
            expect(project_storage.project_folder_mode_possible?("inactive")).to be true
          end

          it "returns false for project_folder_mode automatic" do
            expect(project_storage.project_folder_mode_possible?("automatic")).to be false
          end

          it "returns true for project_folder_mode manual" do
            expect(project_storage.project_folder_mode_possible?("manual")).to be true
          end
        end

        context "when the storage is a nextcloud storage" do
          let(:storage) { build_stubbed(:nextcloud_storage, :as_not_automatically_managed) }

          it "returns true for project_folder_mode inactive" do
            expect(project_storage.project_folder_mode_possible?("inactive")).to be true
          end

          it "returns false for project_folder_mode automatic" do
            expect(project_storage.project_folder_mode_possible?("automatic")).to be false
          end

          it "returns true for project_folder_mode manual" do
            expect(project_storage.project_folder_mode_possible?("manual")).to be true
          end
        end
      end
    end

    describe "#project_folder_mode" do
      let(:project_storage) { build(:project_storage) }

      it do
        expect(project_storage).to define_enum_for(:project_folder_mode)
                                     .with_values(inactive: "inactive", manual: "manual", automatic: "automatic")
                                     .with_prefix(:project_folder)
                                     .backed_by_column_of_type(:string)
      end
    end

    describe "#open" do
      let(:user) { create(:user, member_with_permissions: { project => permissions }) }
      let(:permissions) { %i[] }
      let(:project_storage) { build(:project_storage, storage:, project_folder_mode:, project_folder_id:, project:) }
      let(:project_folder_id) { nil }

      context "with an Edoc DDS storage" do
        let(:storage) { create(:edoc_dds_storage) }
        let(:project_folder_mode) { "inactive" }
        let(:doc_link) { "https://edoc.thape.com.cn:8022/index.html#doc/enterprise/7612553" }

        before do
          allow(project).to receive(:profile).and_return(Struct.new(:doc_link).new(doc_link))
        end

        it "opens the project document link" do
          expect(project_storage.open(user).result).to eq(doc_link)
        end

        it "links directly to the project documents in the sidebar" do
          expect(project_storage.open_project_storage_url).to eq(doc_link)
        end

        context "with a manually configured folder" do
          let(:project_folder_mode) { "manual" }
          let(:project_folder_id) { "folder:123" }

          it "opens the project document link" do
            expect(project_storage.open(user).result).to eq(doc_link)
          end
        end

        context "without a document link" do
          let(:doc_link) { "" }

          it "opens the storage root" do
            expect(project_storage.open(user).result)
              .to eq("#{storage.host}/index.html#doc/enterprise/#{storage.root_folder_id}")
          end
        end

        context "without a project profile" do
          before do
            allow(project).to receive(:profile).and_return(nil)
          end

          it "opens the storage root" do
            expect(project_storage.open(user).result)
              .to eq("#{storage.host}/index.html#doc/enterprise/#{storage.root_folder_id}")
          end
        end

        context "with an unsafe document link" do
          let(:doc_link) { "javascript:alert(1)" }

          it "falls back to the storage route" do
            project_storage.save!
            expect(project_storage.open_project_storage_url).to include("/project_storages/")
          end
        end
      end

      context "when inactive" do
        let(:project_folder_mode) { "inactive" }

        it "opens storage" do
          expect(project_storage.open(user).result).to eq("#{storage.host}index.php/apps/files")
        end
      end

      context "when manual" do
        let(:project_folder_mode) { "manual" }

        context "when project_folder_id is missing" do
          it "opens storage" do
            expect(project_storage.open(user).result).to eq("#{storage.host}index.php/apps/files")
          end
        end

        context "when project_folder_id is present" do
          let(:project_folder_id) { "123" }

          it "opens project_folder" do
            expect(project_storage.open(user).result).to eq("#{storage.host}index.php/f/123?openfile=1")
          end
        end
      end

      context "when automatic" do
        let(:project_folder_mode) { "automatic" }

        context "when user has no permissions to read files in storage" do
          let(:project_folder_mode) { "automatic" }

          it "opens storage" do
            expect(project_storage.open(user).result).to eq("#{storage.host}index.php/apps/files")
          end
        end

        context "when user has permissions to read files in storage" do
          let(:permissions) { %i[read_files] }

          context "when project_folder_id is missing" do
            it "opens storage" do
              expect(project_storage.open(user).result).to eq("#{storage.host}index.php/apps/files")
            end
          end

          context "when project_folder_id is present" do
            let(:project_folder_id) { "123" }

            it "opens project_folder" do
              expect(project_storage.open(user).result).to eq("#{storage.host}index.php/f/123?openfile=1")
            end
          end
        end
      end
    end
  end
end

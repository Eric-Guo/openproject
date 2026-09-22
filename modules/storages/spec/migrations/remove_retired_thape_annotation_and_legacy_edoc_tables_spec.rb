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
require Rails.root.join("modules/storages/db/migrate/20260922120000_remove_retired_thape_annotation_and_legacy_edoc_tables")

RSpec.describe RemoveRetiredThapeAnnotationAndLegacyEdocTables, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  let(:connection) { ActiveRecord::Base.connection }
  let(:storage) { create(:edoc_dds_storage) }
  let(:work_package) { create(:work_package) }
  let!(:file_link) { create(:file_link, storage:, container: work_package, origin_id: "file:306") }

  before do
    storage.update!(provider_fields: storage.provider_fields.merge("annotator_host" => "https://annotator.example.com"))

    connection.create_table(:work_package_edoc_folders, force: true) do |t|
      t.bigint :work_package_id
      t.integer :folder_id
    end
    connection.create_table(:work_package_edoc_files, force: true) do |t|
      t.integer :folder_id
      t.integer :file_id
      t.integer :status
    end
    connection.create_table(:th_annotation_documents, force: true) do |t|
      t.string :uuid
      t.integer :target_id
    end

    connection.execute("INSERT INTO work_package_edoc_folders (work_package_id, folder_id) VALUES (#{work_package.id}, 200)")
    connection.execute("INSERT INTO work_package_edoc_files (folder_id, file_id, status) VALUES (200, 306, 1)")
    connection.execute("INSERT INTO th_annotation_documents (uuid, target_id) VALUES ('retired-document', 123)")
  end

  def retired_tables
    described_class::RETIRED_TABLES.select { connection.table_exists?(it) }
  end

  it "drops retired metadata while preserving migrated file links and storage credentials" do
    expect { migrate }.not_to change(Storages::FileLink, :count)

    expect(retired_tables).to be_empty
    expect(file_link.reload.origin_id).to eq("file:306")
    expect(storage.reload.provider_fields).not_to have_key("annotator_host")
    expect(storage.token).to eq("secret-token")
    expect(storage.root_folder_id).to eq("100")
  end

  it "accepts file links with unprefixed remote IDs" do
    file_link.update!(origin_id: "306")

    migrate

    expect(retired_tables).to be_empty
  end

  it "refuses to drop any metadata when a completed file has no migrated link" do
    file_link.delete

    expect { migrate }.to raise_error(ActiveRecord::MigrationError, /1 completed legacy EDoc file mappings/)
    expect(retired_tables).to match_array(described_class::RETIRED_TABLES)
    expect(storage.reload.provider_fields).to have_key("annotator_host")
  end

  it "does not accept a link for a different work package" do
    file_link.update!(container: create(:work_package))

    expect { migrate }.to raise_error(ActiveRecord::MigrationError, /1 completed legacy EDoc file mappings/)
    expect(retired_tables).to match_array(described_class::RETIRED_TABLES)
  end

  it "does not accept a link from another storage provider" do
    file_link.update!(storage: create(:nextcloud_storage))

    expect { migrate }.to raise_error(ActiveRecord::MigrationError, /1 completed legacy EDoc file mappings/)
  end

  it "refuses completed files with missing folder rows" do
    connection.execute("DELETE FROM work_package_edoc_folders")

    expect { migrate }.to raise_error(ActiveRecord::MigrationError, /1 completed legacy EDoc file mappings/)
  end

  it "refuses completed files when the folder table is missing" do
    connection.drop_table(:work_package_edoc_folders)

    expect { migrate }.to raise_error(ActiveRecord::MigrationError, /without their folder mappings/)
    expect(connection.table_exists?(:th_annotation_documents)).to be true
    expect(connection.table_exists?(:work_package_edoc_files)).to be true
  end

  it "discards incomplete upload metadata" do
    file_link.delete
    connection.execute("UPDATE work_package_edoc_files SET status = 0")

    migrate

    expect(retired_tables).to be_empty
  end

  it "handles an absent legacy file table" do
    connection.drop_table(:work_package_edoc_files)

    migrate

    expect(retired_tables).to be_empty
  end

  it "can run again when the retired tables are absent" do
    migrate

    expect { ActiveRecord::Migration.suppress_messages { described_class.new.up } }.not_to raise_error
  end

  it "does not claim to restore deleted data on rollback" do
    expect { described_class.new.down }.to raise_error(ActiveRecord::IrreversibleMigration)
  end
end

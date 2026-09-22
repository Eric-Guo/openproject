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

class RemoveRetiredThapeAnnotationAndLegacyEdocTables < ActiveRecord::Migration[8.0]
  RETIRED_TABLES = %i[th_annotation_documents work_package_edoc_files work_package_edoc_folders].freeze

  def up
    tables = RETIRED_TABLES.select { table_exists?(it) }
    tables.each { execute "LOCK TABLE #{quote_table_name(it)} IN ACCESS EXCLUSIVE MODE" }

    verify_migrated_file_links!

    tables.each { drop_table(it) }

    execute <<~SQL.squish
      UPDATE storages
      SET provider_fields = provider_fields - 'annotator_host'
      WHERE provider_type = 'Storages::EdocDdsStorage'
        AND provider_fields ? 'annotator_host'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Retired annotation and legacy EDoc metadata cannot be restored."
  end

  private

  def verify_migrated_file_links!
    return unless table_exists?(:work_package_edoc_files)
    return unless select_value("SELECT 1 FROM work_package_edoc_files WHERE status = 1 LIMIT 1")

    unless table_exists?(:work_package_edoc_folders)
      raise ActiveRecord::MigrationError, "Cannot verify completed legacy EDoc files without their folder mappings."
    end

    missing_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM work_package_edoc_files files
      LEFT JOIN work_package_edoc_folders folders ON folders.folder_id = files.folder_id
      WHERE files.status = 1
        AND NOT EXISTS (
          SELECT 1
          FROM file_links
          JOIN storages ON storages.id = file_links.storage_id
          WHERE storages.provider_type = 'Storages::EdocDdsStorage'
            AND file_links.container_type = 'WorkPackage'
            AND file_links.container_id = folders.work_package_id
            AND file_links.origin_id IN (CONCAT('file:', files.file_id), files.file_id::text)
        )
    SQL

    return if missing_count.zero?

    raise ActiveRecord::MigrationError,
          "#{missing_count} completed legacy EDoc file mappings have no migrated file link. " \
          "Reconcile them before dropping the legacy tables."
  end
end

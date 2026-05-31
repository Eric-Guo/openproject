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

class BackfillEdocDdsStorageFromLegacyWorkPackageEdoc < ActiveRecord::Migration[8.0]
  PROVIDER_TYPE = "Storages::EdocDdsStorage"
  STORAGE_NAME = "Edoc DDS"
  LEGACY_FOLDER_TABLE = "work_package_edoc_folders"
  LEGACY_FILE_TABLE = "work_package_edoc_files"
  DEFAULT_ANNOTATOR_HOST = "https://annotator.thape.com.cn"

  def up
    return unless legacy_tables_available?
    return unless edoc_configured?

    storage_id = ensure_storage
    ensure_project_storages(storage_id)
    ensure_file_links(storage_id)
  end

  def down
    # Keep migrated file links and storage mappings intact.
  end

  private

  def legacy_tables_available?
    table_exists?(LEGACY_FOLDER_TABLE) && table_exists?(LEGACY_FILE_TABLE)
  end

  def edoc_configured?
    edoc_host.present? && edoc_token.present? && root_folder_id.present?
  end

  def ensure_storage
    existing_id = select_value(<<~SQL.squish)
      SELECT id
      FROM storages
      WHERE provider_type = #{quote(PROVIDER_TYPE)}
      ORDER BY id ASC
      LIMIT 1
    SQL

    return update_existing_storage(existing_id) if existing_id.present?

    insert_storage
  end

  def update_existing_storage(id)
    execute <<~SQL.squish
      UPDATE storages
      SET host = COALESCE(NULLIF(host, ''), #{quote(edoc_host)}),
          provider_fields = #{quote(provider_fields.to_json)}::jsonb || provider_fields,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = #{id.to_i}
    SQL

    id.to_i
  end

  def insert_storage
    execute <<~SQL.squish
      INSERT INTO storages
        (provider_type, name, host, creator_id, provider_fields, health_status, health_changed_at, health_checked_at,
         created_at, updated_at)
      VALUES
        (#{quote(PROVIDER_TYPE)}, #{quote(available_storage_name)}, #{quote(edoc_host)}, #{system_user_id},
         #{quote(provider_fields.to_json)}::jsonb, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
         CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL

    select_value(<<~SQL.squish).to_i
      SELECT id
      FROM storages
      WHERE provider_type = #{quote(PROVIDER_TYPE)}
      ORDER BY id DESC
      LIMIT 1
    SQL
  end

  def ensure_project_storages(storage_id)
    execute <<~SQL.squish
      INSERT INTO project_storages
        (project_id, storage_id, creator_id, project_folder_mode, created_at, updated_at)
      SELECT DISTINCT work_packages.project_id, #{storage_id}, #{system_user_id}, 'inactive',
             CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM #{LEGACY_FOLDER_TABLE}
      JOIN work_packages ON work_packages.id = #{LEGACY_FOLDER_TABLE}.work_package_id
      WHERE work_packages.project_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM project_storages
          WHERE project_storages.project_id = work_packages.project_id
            AND project_storages.storage_id = #{storage_id}
        )
    SQL
  end

  def ensure_file_links(storage_id)
    execute <<~SQL.squish
      INSERT INTO file_links
        (storage_id, creator_id, container_id, container_type, origin_id, origin_name, origin_mime_type,
         origin_created_at, origin_updated_at, created_at, updated_at)
      SELECT #{storage_id},
             COALESCE(users.id, #{system_user_id}),
             #{LEGACY_FOLDER_TABLE}.work_package_id,
             'WorkPackage',
             CONCAT('file:', #{LEGACY_FILE_TABLE}.file_id),
             #{LEGACY_FILE_TABLE}.file_name,
             #{legacy_file_mime_type_expression},
             #{LEGACY_FILE_TABLE}.created_at,
             #{LEGACY_FILE_TABLE}.updated_at,
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM #{LEGACY_FILE_TABLE}
      JOIN #{LEGACY_FOLDER_TABLE} ON #{LEGACY_FOLDER_TABLE}.folder_id = #{LEGACY_FILE_TABLE}.folder_id
      LEFT JOIN users ON users.id = #{legacy_file_creator_id_expression}
      WHERE #{LEGACY_FILE_TABLE}.status = 1
        AND NOT EXISTS (
          SELECT 1
          FROM file_links
          WHERE file_links.storage_id = #{storage_id}
            AND file_links.container_id = #{LEGACY_FOLDER_TABLE}.work_package_id
            AND file_links.container_type = 'WorkPackage'
            AND file_links.origin_id IN (
              CONCAT('file:', #{LEGACY_FILE_TABLE}.file_id),
              #{LEGACY_FILE_TABLE}.file_id::text
            )
        )
    SQL
  end

  def provider_fields
    {
      automatically_managed: false,
      automatic_management_enabled: false,
      health_notifications_enabled: true,
      root_folder_id:,
      token: edoc_token,
      annotator_host:
    }
  end

  def available_storage_name
    return STORAGE_NAME unless storage_name_exists?(STORAGE_NAME)

    counter = 2
    loop do
      candidate = "#{STORAGE_NAME} #{counter}"
      return candidate unless storage_name_exists?(candidate)

      counter += 1
    end
  end

  def storage_name_exists?(name)
    select_value("SELECT 1 FROM storages WHERE LOWER(name) = LOWER(#{quote(name)}) LIMIT 1").present?
  end

  def legacy_file_creator_id_expression
    if column_exists?(LEGACY_FILE_TABLE, :user_id)
      "#{LEGACY_FILE_TABLE}.user_id"
    else
      "NULL"
    end
  end

  def legacy_file_mime_type_expression
    if column_exists?(LEGACY_FILE_TABLE, :content_type)
      "NULLIF(#{LEGACY_FILE_TABLE}.content_type, '')"
    else
      "NULL"
    end
  end

  def edoc_host
    ENV.fetch("EDOC_HOST", nil)
  end

  def edoc_token
    ENV.fetch("EDOC_TOKEN", nil)
  end

  def root_folder_id
    ENV.fetch("EDOC_WP_FOLDER", nil)
  end

  def annotator_host
    ENV.fetch("TH_ANNOTATOR_HOST", DEFAULT_ANNOTATOR_HOST)
  end

  def system_user_id
    @system_user_id ||= User.system.id
  end
end

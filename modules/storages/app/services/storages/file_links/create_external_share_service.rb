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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module FileLinks
    class CreateExternalShareService
      EXPIRATIONS = { "day" => 1.day, "week" => 7.days, "month" => 1.month }.freeze

      def self.available?(storage)
        storage.provider_type_edoc_dds? && defined?(::Edoc::FolderPublishes)
      end

      def self.shareable?(file_link)
        file_link.origin_id.match?(/\A(?:file:)?[1-9]\d*\z/) &&
          file_link.origin_mime_type != "application/x-op-directory"
      end

      def initialize(user:, work_package:, project_storage:)
        @user = user
        @work_package = work_package
        @project_storage = project_storage
        @storage = project_storage.storage
      end

      def call(file_link_ids:, expiration:)
        error = validation_error(expiration)
        return failure(error) if error

        file_links = selected_file_links(file_link_ids)
        return failure(:invalid_selection) if file_links.empty?

        expires_at = Time.current + EXPIRATIONS.fetch(expiration)
        create_snapshot(file_links)
        ServiceResult.success(result: { url: publish_snapshot(expires_at), expires_at: })
      rescue ::Edoc::Error
        remove_snapshot
        failure(:creation_failed)
      end

      private

      def validation_error(expiration)
        return :not_allowed unless allowed?
        return :invalid_expiration unless EXPIRATIONS.key?(expiration)
        return :configuration_error unless matching_host?

        nil
      end

      def allowed?
        self.class.available?(@storage) &&
          @work_package.project_id == @project_storage.project_id &&
          @work_package.visible?(@user) &&
          @user.allowed_in_project?(:view_file_links, @work_package.project) &&
          @user.allowed_in_project?(:manage_file_links, @work_package.project)
      end

      def matching_host?
        ::Edoc::Config.host.present? && ::Edoc::Config.token.present? &&
          ::Edoc::Config.host.delete_suffix("/") == @storage.host.delete_suffix("/")
      end

      def selected_file_links(ids)
        return [] unless ids.is_a?(Array) && ids.all? { it.to_s.match?(/\A[1-9]\d*\z/) }

        ids = ids.map(&:to_i).uniq
        links = ::Storages::FileLink.where(container: @work_package, storage: @storage, id: ids).order(:id).to_a
        return [] unless links.size == ids.size && links.all? { self.class.shareable?(it) }

        links.uniq(&:origin_id)
      end

      def create_snapshot(file_links)
        @snapshot_folder_id = create_folder(@storage.root_folder_id, "WP-#{@work_package.id}-#{SecureRandom.uuid}")
        file_links.group_by { it.origin_name.downcase }.each_value do |links|
          links.each do |file_link|
            copy_file(file_link, duplicate_name: links.size > 1)
          end
        end
      end

      def copy_file(file_link, duplicate_name:)
        target = duplicate_name ? create_folder(@snapshot_folder_id, file_link.id.to_s) : @snapshot_folder_id
        ::Edoc::Documents.copy(target_folder_id: target, file_ids: [file_link.origin_id.delete_prefix("file:")])
      end

      def publish_snapshot(expires_at)
        code = ::Edoc::FolderPublishes.create(
          [@snapshot_folder_id],
          name: I18n.t("storages.external_shares.share_name", id: @work_package.id),
          end_time: expires_at.strftime("%Y-%m-%d %H:%M:%S"),
          auth_type: 1,
          can_download: true
        )
        ::Edoc::FolderPublishes.url(code)
      end

      def create_folder(parent_id, name)
        folder = ::Edoc::Folders.create(parent_folder_id: parent_id, name:) # rubocop:disable Rails/SaveBang
        folder.fetch(:folder_id).tap do |id|
          raise ::Edoc::Error, "DDS did not return a snapshot folder ID" unless id.to_s.match?(/\A[1-9]\d*\z/)
        end
      end

      def remove_snapshot
        ::Edoc::Folders.remove(@snapshot_folder_id) if @snapshot_folder_id
      rescue ::Edoc::Error
        Rails.logger.warn("Could not remove DDS share snapshot #{@snapshot_folder_id}")
      end

      def failure(key)
        ServiceResult.failure(message: I18n.t("storages.external_shares.errors.#{key}"))
      end
    end
  end
end

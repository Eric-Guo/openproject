# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTracking
    class TimeEntryRow < OpPrimer::BorderBoxRowComponent
      def button_links
        [
          action_menu
        ]
      end

      def action_menu
        return nil unless User.current.allowed_in_work_package?(:edit_own_time_entries, time_entry.work_package)
        return nil if (time_entry.spent_on <= 9.days.ago.to_date || time_entry.approved_by_id.present?) && !User.current.admin?

        render(Primer::Alpha::ActionMenu.new) do |menu|
          menu.with_show_button(icon: "kebab-horizontal", "aria-label": t("label_more"), scheme: :invisible)
          menu.with_item(
            content_arguments: {
              data: {
                "turbo-stream" => true
              }
            },
            tag: :a,
            label: t("label_edit"),
            href: dialog_time_entry_path(time_entry, onlyMe: true)
          ) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end
      end

      def spent_on
        I18n.l(time_entry.spent_on)
      end

      def time # rubocop:disable Metrics/AbcSize
        return if time_entry.start_time.blank?

        times = [I18n.l(time_entry.start_timestamp, format: :time)]

        times << if time_entry.start_timestamp.to_date == time_entry.end_timestamp.to_date
                   I18n.l(time_entry.end_timestamp, format: :time)
                 else
                   I18n.l(time_entry.end_timestamp, format: :short)
                 end

        times.join(" - ")
      end

      def hours
        DurationConverter.output(time_entry.hours, format: :hours_and_minutes)
      end

      def subject
        render(Primer::Beta::Link.new(href: project_work_package_path(time_entry.project, time_entry.work_package),
                                      underline: false)) do
          "##{time_entry.work_package.id}"
        end + " - #{time_entry.work_package.subject}"
      end

      def project
        render(Primer::Beta::Link.new(href: project_path(time_entry.project), underline: false)) do
          time_entry.project.name
        end
      end

      def activity
        time_entry.activity&.name
      end

      delegate :comments, to: :time_entry

      private

      def time_entry
        model
      end
    end
  end
end

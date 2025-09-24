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

namespace :openproject do
  namespace :my_page do
    desc "Apply the configured My Page grid to all non-builtin users."
    task apply_grid: :environment do
      layout = {
        row_count: 1,
        column_count: 2,
        widgets: [
          {
            identifier: "project_favorites",
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              "name" => "\u6536\u85CF\u7684\u9879\u76EE"
            }
          },
          {
            identifier: "work_packages_table",
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              "name" => "\u5206\u914D\u7ED9\u6211\u7684\u5DE5\u4F5C\u5305",
              "queryId" => "152"
            }
          }
        ]
      }.freeze

      processed = 0
      created = 0
      updated = 0
      failures = []

      User.not_builtin.find_each do |user|
        processed += 1

        ActiveRecord::Base.transaction do
          my_page = Grids::MyPage.find_or_initialize_by(user: user)
          new_record = my_page.new_record?

          my_page.row_count = layout.fetch(:row_count)
          my_page.column_count = layout.fetch(:column_count)
          my_page.options = {}
          my_page.name = nil

          if my_page.persisted?
            my_page.widgets.destroy_all
            my_page.widgets.reload
          end

          layout.fetch(:widgets).each do |widget_definition|
            attrs = widget_definition.deep_dup
            options = attrs.delete(:options) || {}

            my_page.widgets.build(attrs.merge(options: options))
          end

          my_page.save!

          new_record ? created += 1 : updated += 1
        end
      rescue StandardError => error
        failures << { user_id: user.id, login: user.login, error: error.message }
        warn "Failed to update My Page for user ##{user.id} (#{user.login}): #{error.message}"
      end

      puts "Processed #{processed} users. Created: #{created}, Updated: #{updated}."

      if failures.any?
        warn "Encountered #{failures.size} failures:"
        failures.each do |failure|
          warn "  user ##{failure.fetch(:user_id)} (#{failure.fetch(:login)}): #{failure.fetch(:error)}"
        end
      end
    end
  end
end

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

class TimeEntry < ApplicationRecord
  # could have used polymorphic association
  # project association here allows easy loading of time entries at project level with one database trip
  belongs_to :project
  belongs_to :work_package
  belongs_to :user
  belongs_to :activity, class_name: "TimeEntryActivity"
  belongs_to :rate, -> { where(type: %w[HourlyRate DefaultHourlyRate]) }, class_name: "Rate"
  belongs_to :logged_by, class_name: "User"

  MIN_TIME = 0 # => 00:00
  MAX_TIME = (60 * 24) - 1 # => 23:59
  SECONDS_PER_HOUR = 3600.0

  acts_as_customizable

  acts_as_journalized

  validates :user_id, :project_id, :spent_on,
            presence: true

  validates :hours,
            presence: true,
            if: -> { !ongoing? }

  validates :hours,
            numericality: {
              message: :invalid
            },
            allow_nil: true

  validates :comments,
            length: { maximum: 1_000 },
            allow_blank: true

  validates :start_time,
            presence: true,
            if: -> { TimeEntry.must_track_start_and_end_time? }

  validates :start_time,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_TIME,
              less_than_or_equal_to: MAX_TIME,
              message: :invalid_time
            },
            allow_blank: true

  scope :on_work_packages, ->(work_packages) { where(work_package_id: work_packages) }

  extend ::TimeEntries::TimeEntryScopes
  include ::Scopes::Scoped
  include Entry::Costs
  include Entry::SplashedDates

  scopes :of_user_and_day,
         :ongoing,
         :ongoing_for_user_other_than

  # TODO: move into service
  before_save :update_costs

  register_journal_formatted_fields "hours", formatter_key: :time_entry_hours
  register_journal_formatted_fields "user_id", formatter_key: :time_entry_named_association
  register_journal_formatted_fields "work_package_id", "activity_id", formatter_key: :named_association
  register_journal_formatted_fields "comments", "spent_on", "start_time", formatter_key: :plaintext

  def self.update_all(updates, conditions = nil, options = {})
    # instead of a update_all, perform an individual update during work_package#move
    # to trigger the update of the costs based on new rates
    if conditions.respond_to?(:keys) && conditions.keys == [:work_package_id] && updates =~ /^project_id = (\d+)$/
      project_id = $1
      time_entries = TimeEntry.where(conditions)
      time_entries.each do |entry|
        entry.project_id = project_id
        entry.save!
      end
    else
      super
    end
  end

  def hours=(value)
    write_attribute :hours, (value.is_a?(String) ? (value.to_hours || value) : value)
  end

  def ongoing_hours
    return nil unless ongoing?

    (Time.zone.now.to_i - created_at.to_i) / SECONDS_PER_HOUR
  end

  def start_time=(value)
    if value.is_a?(String) && value =~ /\A(\d{1,2}):(\d{2})\z/
      super(($1.to_i * 60) + $2.to_i)
    else
      super
    end
  end

  def approved_hours=(value)
    write_attribute :approved_hours, (value.is_a?(String) ? (value.to_hours || value) : value)
  end

  def sz_approved_hours=(value)
    write_attribute :sz_approved_hours, (value.is_a?(String) ? (value.to_hours || value) : value)
  end

  # Returns true if the time entry can be edited by usr, otherwise false
  def editable_by?(usr)
    (usr == user && usr.allowed_in_work_package?(:edit_own_time_entries, work_package)) ||
      usr.allowed_in_project?(:edit_time_entries, project)
  end

  def current_rate
    user.rate_at(spent_on, project_id)
  end

  def visible_by?(usr)
    usr.allowed_in_project?(:view_time_entries, project) ||
      (user_id == usr.id && usr.allowed_in_work_package?(:view_own_time_entries, work_package))
  end

  def costs_visible_by?(usr)
    usr.allowed_in_project?(:view_hourly_rates, project) ||
      (user_id == usr.id && usr.allowed_in_project?(:view_own_hourly_rate, project))
  end

  def has_start_and_end_time?
    start_time.present?
  end

  def start_timestamp # rubocop:disable Metrics/AbcSize
    return nil if start_time.blank?
    return nil if time_zone.blank?
    return nil if spent_on.blank?

    time_zone_object.local(spent_on.year, spent_on.month, spent_on.day, start_time / 60, start_time % 60)
  end

  def end_timestamp
    return nil if start_time.blank?
    return nil if time_zone.blank?
    return nil if spent_on.blank?

    if ongoing?
      start_timestamp + ongoing_hours.hours
    else
      start_timestamp + hours.hours
    end
  end

  class << self
    def can_track_start_and_end_time?
      Setting.allow_tracking_start_and_end_times?
    end

    def must_track_start_and_end_time?
      can_track_start_and_end_time? &&
        Setting.enforce_tracking_start_and_end_times?
    end
  end

  private

  def cost_attribute
    hours
  end

  def time_zone_object
    ActiveSupport::TimeZone[time_zone]
  end
end

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

module Users::Invitation
  class FormModel < ApplicationRecord
    include Tableless

    belongs_to :project
    attribute :project_id, :integer, default: nil
    attribute :role_id, :integer, default: nil
    attribute :principal_type, :text, default: nil
    attribute :id_or_email, :text, default: nil
    attribute :message, :text, default: nil

    validates :project_id, presence: true, on: :project_step
    validates :principal_type,
              inclusion: { in: ->(*) { available_principal_types } },
              on: :project_step

    validates :id_or_email, presence: true, on: :principal_step
    validates :role_id, presence: true, on: :principal_step

    def self.available_principal_types
      %w[User PlaceholderUser Group]
    end

    def project_name
      project&.name || project_id
    end

    def to_h
      {
        project_id:,
        role_id:,
        principal_type:,
        id_or_email:,
        message:
      }
    end
  end
end

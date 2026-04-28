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

module Projects
  module Settings
    class ProjectProfileForm < ApplicationForm
      DEFAULT_TYPE_ID = 3
      TYPE_IDS = [1, 2, 3].freeze

      form do |f|
        f.fields_for(:profile, project_profile) do |builder|
          ProfileFieldsForm.new(builder)
        end
      end

      private

      def project_profile
        model.profile || ProjectProfile.new(project: model, type_id: DEFAULT_TYPE_ID)
      end

      class ProfileFieldsForm < ApplicationForm
        form do |f|
          f.select_list(
            name: :type_id,
            label: attribute_name(:type_id),
            required: true,
            include_blank: false,
            input_width: :medium
          ) do |list|
            TYPE_IDS.each do |type_id|
              list.option(
                label: I18n.t("activerecord.attributes.project_profile.type_id_list.#{type_id}"),
                value: type_id,
                selected: model.type_id == type_id
              )
            end
          end

          f.text_field(
            name: :name,
            label: attribute_name(:name),
            input_width: :large
          )

          f.text_field(
            name: :code,
            label: attribute_name(:code),
            required: true,
            input_width: :medium
          )

          f.text_field(
            name: :doc_link,
            label: attribute_name(:doc_link),
            input_width: :large
          )
        end
      end
    end
  end
end

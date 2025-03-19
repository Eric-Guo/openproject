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

module API
  module V3
    module Queries
      module Schemas
        class ProjectPhaseFilterDependencyRepresenter < FilterDependencyRepresenter
          schema_with_allowed_collection :values,
                                         type: ->(*) { type },
                                         writable: true,
                                         has_default: false,
                                         required: true,
                                         values_callback: ->(*) {
                                           represented.custom_field.possible_project_phases(represented.context)
                                         },
                                         value_representer: ProjectPhases::ProjectPhaseRepresenter,
                                         link_factory: ->(value) {
                                           {
                                             href: api_v3_paths.project_phase(value.id),
                                             title: value.definition.name
                                           }
                                         },
                                         show_if: ->(*) {
                                           value_required?
                                         }


          def json_cache_key
            if filter.project
              super + [filter.project.id]
            else
              super
            end
          end

          def href_callback
            api_v3_paths.project_phase_definitions
          end

          def type
            "[]ProjectPhaseDefinition"
          end
        end
      end
    end
  end
end

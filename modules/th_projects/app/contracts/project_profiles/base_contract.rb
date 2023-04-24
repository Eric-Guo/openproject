#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module ProjectProfiles
  class BaseContract < ::ModelContract
    include AssignableValuesContract

    attribute :type_id
    attribute :name
    attribute :code
    attribute :doc_link

    validate :validate_user_allowed_to_manage

    def assignable_projects
      Project
        .allowed_to(user, :add_subprojects)
        .where.not(id: project.self_and_descendants)
    end

    delegate :assignable_versions, to: :model

    private

    def validate_user_allowed_to_manage
      with_unchanged_id do
        errors.add :base, :error_unauthorized unless user.allowed_to?(manage_permission, model.project)
      end
    end

    def manage_permission
      raise NotImplementedError
    end

    def with_unchanged_id
      project_id = model.project_id
      model.id = model.id_was

      yield
    ensure
      model.id = model.id_was
    end
  end
end

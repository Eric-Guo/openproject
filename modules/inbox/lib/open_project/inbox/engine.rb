# OpenProject Calendar module
#
# Copyright (C) 2021 OpenProject GmbH
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

module OpenProject::Inbox
  class Engine < ::Rails::Engine
    engine_name :openproject_inbox

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-inbox',
             author_url: 'https://www.openproject.org',
             bundled: true,
             settings: {},
             name: 'OpenProject Inbox' do
      project_module :inbox_view, dependencies: :work_package_tracking do
        permission :view_inbox,
                   { 'inbox/inboxes': %i[index show] },
                   dependencies: %i[view_work_packages],
                   contract_actions: { inbox: %i[read] }
      end

      menu :project_menu,
           :inbox_view,
           { controller: '/inbox/inboxes', action: 'index' },
           caption: :label_inbox_plural,
           icon: 'bell',
           before: :activity

      menu :project_menu,
           :inbox_menu,
           { controller: '/inbox/inboxes', action: 'index' },
           parent: :inbox_view,
           partial: 'inbox/inboxes/menu',
           last: true,
           caption: :label_inbox_plural
    end
  end
end

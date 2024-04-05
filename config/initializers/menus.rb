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

require "redmine/menu_manager"

Redmine::MenuManager.map :top_menu do |menu|
  # projects menu will be added by
  # Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node
  menu.push :projects,
            { controller: "/projects", project_id: nil, action: "index" },
            context: :modules,
            caption: I18n.t("label_projects_menu"),
            icon: "project",
            if: ->(_) {
              User.current.logged? || !Setting.login_required?
            }

  menu.push :activity,
            { controller: "/activities", action: "index" },
            context: :modules,
            icon: "history"

  menu.push :work_packages,
            { controller: "/work_packages", project_id: nil, state: nil, action: "index" },
            context: :modules,
            caption: I18n.t("label_work_package_plural"),
            icon: "op-view-list",
            if: ->(_) {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_in_any_work_package?(:view_work_packages)
            }
  menu.push :news,
            { controller: "/news", project_id: nil, action: "index" },
            context: :modules,
            caption: I18n.t("label_news_plural"),
            icon: "megaphone",
            if: ->(_) {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_in_any_project?(:view_news)
            }

  menu.push :help,
            OpenProject::Static::Links.help_link,
            last: true,
            caption: "",
            icon: "question",
            html: { accesskey: OpenProject::AccessKeys.key_for(:help),
                    title: I18n.t("label_help"),
                    target: "_blank" }
end

Redmine::MenuManager.map :quick_add_menu do |menu|
  menu.push :new_project,
            ->(project) {
              { controller: "/projects", action: :new, project_id: nil, parent_id: project&.id }
            },
            caption: ->(_) { Project.model_name.human },
            icon: "plus",
            html: {
              aria: { label: I18n.t(:label_project_new) },
              title: I18n.t(:label_project_new)
            },
            if: ->(project) {
              User.current.allowed_globally?(:add_project) ||
                User.current.allowed_in_project?(:add_subprojects, project)
            }

  menu.push :invite_user,
            nil,
            caption: :label_invite_user,
            icon: "person-add",
            html: {
              "invite-user-modal-augment": "invite-user-modal-augment"
            },
            if: ->(_) { User.current.allowed_in_any_project?(:manage_members) }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :timers,
            { controller: "/my/timer", action: "show" },
            partial: "/my/timer/menu"
  menu.push :my_page,
            :my_page_path,
            caption: I18n.t("my_page.label"),
            if: ->(_) { User.current.logged? }
  menu.push :my_profile,
            { controller: "/users", action: "show", id: "me" },
            caption: :label_my_activity,
            if: ->(_) { User.current.logged? }
  menu.push :my_account,
            { controller: "/my", action: "account" },
            if: ->(_) { User.current.logged? }
  menu.push :administration,
            { controller: "/admin", action: "index" },
            if: ->(_) {
              User.current.allowed_globally?({ controller: "/admin", action: "index" })
            }
  menu.push :logout,
            :signout_path,
            if: ->(_) { User.current.logged? },
            html: {
              data: {
                # Turbo-drive needs to be disabled, as we might redirect to other origins
                # as a result here (e.g., post logout SSO redirects).
                turbo: false
              }
            }
end

Redmine::MenuManager.map :global_menu do |menu|
  # Homescreen
  menu.push :home,
            { controller: "/homescreen", action: "index" },
            icon: "home",
            first: true

  # Projects
  menu.push :projects,
            { controller: "/projects", project_id: nil, action: "index" },
            caption: I18n.t("label_projects_menu"),
            icon: "project",
            after: :my_page,
            if: ->(_) {
              User.current.logged? || !Setting.login_required?
            }

  menu.push :projects_query_select,
            { controller: "/projects", project_id: nil, action: "index" },
            parent: :projects,
            partial: "projects/menus/menu"

  # Activity
  menu.push :activity,
            { controller: "/activities", action: "index" },
            icon: "history",
            after: :projects

  menu.push :activity_filters,
            { controller: "/activities", action: "index" },
            parent: :activity,
            partial: "activities/filters_menu"

  # Work packages
  menu.push :work_packages,
            { controller: "/work_packages", action: "index" },
            caption: :label_work_package_plural,
            icon: "op-view-list",
            after: :activity

  menu.push :work_packages_query_select,
            { controller: "/work_packages", action: "index" },
            parent: :work_packages,
            partial: "work_packages/menus/menu"

  # News
  menu.push :news,
            { controller: "/news", project_id: nil, action: "index" },
            caption: I18n.t("label_news_plural"),
            icon: "megaphone",
            after: :boards,
            if: ->(_) {
              (User.current.logged? || !Setting.login_required?) &&
                User.current.allowed_in_any_project?(:view_news)
            }
end

Redmine::MenuManager.map :notifications_menu do |menu|
  menu.push :notification_grouping_select,
            { controller: "/my", action: "notifications" },
            partial: "notifications/menus/menu"
end

Redmine::MenuManager.map :my_menu do |menu|
  menu.push :account,
            { controller: "/my", action: "account" },
            caption: :label_profile,
            icon: "person-fill"
  menu.push :settings,
            { controller: "/my", action: "settings" },
            caption: :label_setting_plural,
            icon: "gear"
  menu.push :interface,
            { controller: "/my", action: "interface" },
            caption: :label_interface,
            icon: "device-desktop"
  menu.push :password,
            { controller: "/my", action: "password" },
            caption: :button_change_password,
            if: ->(_) { User.current.change_password_allowed? },
            icon: "lock"
  menu.push :access_token,
            { controller: "/my", action: "access_token" },
            caption: I18n.t("my_account.access_tokens.access_tokens"),
            icon: "key"
  menu.push :sessions,
            { controller: "/my/sessions", action: :index },
            caption: :"users.sessions.title",
            icon: "op-installation-services"
  menu.push :notifications,
            { controller: "/my", action: "notifications" },
            caption: I18n.t("js.notifications.settings.title"),
            icon: "bell"
  menu.push :reminders,
            { controller: "/my", action: "reminders" },
            caption: I18n.t("js.reminders.settings.title"),
            icon: "unread"

  menu.push :delete_account, :delete_my_account_info_path,
            caption: I18n.t("account.delete"),
            param: :user_id,
            if: ->(_) { Setting.users_deletable_by_self? },
            last: :delete_account,
            icon: "trash"
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :admin_overview,
            { controller: "/admin", action: :index },
            if: ->(_) { User.current.admin? },
            caption: :label_overview,
            icon: "home",
            first: true

  menu.push :users,
            { controller: "/users" },
            if: ->(_) {
              !User.current.admin? &&
                (User.current.allowed_globally?(:manage_user) || User.current.allowed_globally?(:create_user))
            },
            caption: :label_user_plural,
            icon: "people"

  menu.push :placeholder_users,
            { controller: "/placeholder_users" },
            if: ->(_) { !User.current.admin? && User.current.allowed_globally?(:manage_placeholder_user) },
            caption: :label_placeholder_user_plural,
            icon: "people"

  menu.push :users_and_permissions,
            { controller: "/users" },
            if: ->(_) { User.current.admin? },
            caption: :label_user_and_permission,
            icon: "people"

  menu.push :user_settings,
            { controller: "/admin/settings/users_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_users_settings,
            parent: :users_and_permissions

  menu.push :users,
            { controller: "/users" },
            if: ->(_) { User.current.admin? },
            caption: :label_user_plural,
            parent: :users_and_permissions

  menu.push :placeholder_users,
            { controller: "/placeholder_users" },
            if: ->(_) { User.current.admin? },
            caption: :label_placeholder_user_plural,
            parent: :users_and_permissions,
            enterprise_feature: "placeholder_users"

  menu.push :groups,
            { controller: "/groups" },
            if: ->(_) { User.current.admin? },
            caption: :label_group_plural,
            parent: :users_and_permissions

  menu.push :roles,
            { controller: "/roles" },
            if: ->(_) { User.current.admin? },
            caption: :label_role_and_permissions,
            parent: :users_and_permissions

  menu.push :permissions_report,
            { controller: "/roles", action: "report" },
            if: ->(_) { User.current.admin? },
            caption: :label_permissions_report,
            parent: :users_and_permissions

  menu.push :user_avatars,
            { controller: "/admin/settings", action: "show_plugin", id: :openproject_avatars },
            if: ->(_) { User.current.admin? },
            caption: :label_avatar_plural,
            parent: :users_and_permissions

  menu.push :admin_work_packages,
            { controller: "/admin/settings/work_packages_general", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_work_package_plural,
            icon: "op-view-list"

  menu.push :work_packages_general,
            { controller: "/admin/settings/work_packages_general", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_general,
            parent: :admin_work_packages

  menu.push :types,
            { controller: "/types" },
            if: ->(_) { User.current.admin? },
            caption: :label_type_plural,
            parent: :admin_work_packages

  menu.push :statuses,
            { controller: "/statuses" },
            if: ->(_) { User.current.admin? },
            caption: :label_status,
            parent: :admin_work_packages

  menu.push :priorities,
            { controller: "/admin/settings/work_package_priorities" },
            if: ->(_) { User.current.admin? },
            caption: IssuePriority.model_name.human(count: :other),
            parent: :admin_work_packages

  menu.push :progress_tracking,
            { controller: "/admin/settings/progress_tracking", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_progress_tracking,
            parent: :admin_work_packages

  menu.push :workflows,
            { controller: "/workflows", action: "edit" },
            if: ->(_) { User.current.admin? },
            caption: ->(_) { Workflow.model_name.human },
            parent: :admin_work_packages

  menu.push :admin_projects_settings,
            { controller: "/admin/settings/project_phase_definitions", action: :index },
            if: ->(_) { User.current.admin? },
            caption: :label_project_plural,
            icon: "project"

  menu.push :project_phase_definitions_settings,
            { controller: "/admin/settings/project_phase_definitions", action: :index },
            if: ->(_) { User.current.admin? },
            caption: :label_project_life_cycle,
            parent: :admin_projects_settings

  menu.push :project_custom_fields_settings,
            { controller: "/admin/settings/project_custom_fields", action: :index },
            if: ->(_) { User.current.admin? },
            caption: :label_project_attributes_plural,
            parent: :admin_projects_settings

  menu.push :new_project_settings,
            { controller: "/admin/settings/new_project_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_project_new,
            parent: :admin_projects_settings

  menu.push :project_lists_settings,
            { controller: "/admin/settings/projects_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_project_list_plural,
            parent: :admin_projects_settings

  menu.push :custom_fields,
            { controller: "/custom_fields" },
            if: ->(_) { User.current.admin? },
            caption: :label_custom_field_plural,
            icon: "op-custom-fields",
            html: { class: "custom_fields" }

  menu.push :custom_actions,
            { controller: "/custom_actions" },
            if: ->(_) { User.current.admin? },
            caption: :"custom_actions.plural",
            parent: :admin_work_packages,
            enterprise_feature: "custom_actions"

  menu.push :attribute_help_texts,
            { controller: "/attribute_help_texts" },
            caption: :"attribute_help_texts.label_plural",
            icon: "question",
            if: ->(_) { User.current.allowed_globally?(:edit_attribute_help_texts) }

  menu.push :calendars_and_dates,
            { controller: "/admin/settings/working_days_and_hours_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_calendars_and_dates,
            icon: "calendar"

  menu.push :working_days_and_hours,
            { controller: "/admin/settings/working_days_and_hours_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_working_days_and_hours,
            parent: :calendars_and_dates

  menu.push :date_format,
            { controller: "/admin/settings/date_format_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_date_format,
            parent: :calendars_and_dates

  menu.push :icalendar,
            { controller: "/admin/settings/icalendar_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_calendar_subscriptions,
            parent: :calendars_and_dates

  menu.push :settings,
            { controller: "/admin/settings/general_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_system_settings,
            icon: "gear"

  menu.push :settings_general,
            { controller: "/admin/settings/general_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_general,
            parent: :settings

  menu.push :settings_languages,
            { controller: "/admin/settings/languages_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_languages,
            parent: :settings

  menu.push :settings_repositories,
            { controller: "/admin/settings/repositories_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_repository_plural,
            parent: :settings

  menu.push :settings_experimental,
            { controller: "/admin/settings/experimental_settings", action: :show },
            if: ->(_) { User.current.admin? && Rails.env.development? },
            caption: :label_experimental,
            parent: :settings

  menu.push :mail_and_notifications,
            { controller: "/admin/settings/aggregation_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :"menus.admin.mails_and_notifications",
            icon: "mail"

  menu.push :notification_settings,
            { controller: "/admin/settings/aggregation_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :"menus.admin.aggregation",
            parent: :mail_and_notifications

  menu.push :mail_notifications,
            { controller: "/admin/settings/mail_notifications_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :"menus.admin.mail_notification",
            parent: :mail_and_notifications

  menu.push :incoming_mails,
            { controller: "/admin/settings/incoming_mails_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_incoming_emails,
            parent: :mail_and_notifications

  menu.push :api_and_webhooks,
            { controller: "/admin/settings/api_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :"menus.admin.api_and_webhooks",
            icon: "op-relations"

  menu.push :api,
            { controller: "/admin/settings/api_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_api_access_key_type,
            parent: :api_and_webhooks

  menu.push :authentication,
            { controller: "/admin/settings/authentication_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_authentication,
            icon: "shield-lock"

  menu.push :authentication_settings,
            { controller: "/admin/settings/authentication_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :"authentication.login_and_registration",
            parent: :authentication

  menu.push :ldap_authentication,
            { controller: "/ldap_auth_sources", action: "index" },
            if: ->(_) { User.current.admin? && !OpenProject::Configuration.disable_password_login? },
            parent: :authentication,
            caption: :label_ldap_auth_source_plural,
            html: { class: "server_authentication" },
            last: true

  menu.push :oauth_applications,
            { controller: "/oauth/applications", action: "index" },
            if: ->(_) { User.current.admin? },
            parent: :authentication,
            caption: :"oauth.application.plural",
            html: { class: "oauth_applications" }

  menu.push :announcements,
            { controller: "/announcements", action: "edit" },
            if: ->(_) { User.current.admin? },
            caption: :label_announcement,
            icon: "megaphone"

  menu.push :plugins,
            { controller: "/admin", action: "plugins" },
            if: ->(_) { User.current.admin? },
            last: true,
            icon: "plug"

  menu.push :backups,
            { controller: "/admin/backups", action: "show" },
            if: ->(_) { OpenProject::Configuration.backup_enabled? && User.current.allowed_globally?(Backup.permission) },
            caption: :label_backup,
            last: true,
            icon: "op-save"

  menu.push :info,
            { controller: "/admin", action: "info" },
            if: ->(_) { User.current.admin? },
            caption: :label_information_plural,
            last: true,
            icon: "info"

  menu.push :custom_style,
            { controller: "/custom_styles", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_custom_style,
            icon: "paintbrush",
            enterprise_feature: "define_custom_style"

  menu.push :colors,
            { controller: "/colors", action: "index" },
            if: ->(_) { User.current.admin? },
            caption: :label_color_plural,
            icon: "meter"

  menu.push :enterprise,
            { controller: "/enterprise_tokens", action: :index },
            caption: :label_enterprise_edition,
            icon: "op-enterprise-addons",
            if: proc { User.current.admin? && OpenProject::Configuration.ee_manager_visible? }

  menu.push :admin_backlogs,
            { controller: "/backlogs_settings", action: :show },
            if: ->(_) { User.current.admin? },
            caption: :label_backlogs,
            icon: "op-backlogs"
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :activity,
            { controller: "/activities", action: "index" },
            if: ->(project) { project.module_enabled?("activity") },
            icon: "history"

  menu.push :activity_filters,
            { controller: "/activities", action: "index" },
            if: ->(project) { project.module_enabled?("activity") },
            parent: :activity,
            partial: "activities/filters_menu"

  menu.push :roadmap,
            { controller: "/versions", action: "index" },
            if: ->(project) { project.shared_versions.any? },
            icon: "milestone"

  menu.push :work_packages,
            { controller: "/work_packages", action: "index" },
            caption: :label_work_package_plural,
            if: ->(project) { project.module_enabled?("work_package_tracking") },
            icon: "op-view-list",
            html: {
              id: "main-menu-work-packages",
              "wp-query-menu": "wp-query-menu"
            }

  menu.push :work_packages_query_select,
            { controller: "/work_packages", action: "index" },
            parent: :work_packages,
            partial: "work_packages/menus/menu",
            last: true,
            caption: :label_all_open_wps

  menu.push :news,
            { controller: "/news", action: "index" },
            caption: :label_news_plural,
            icon: "megaphone"

  menu.push :forums,
            { controller: "/forums", action: "index", id: nil },
            caption: :label_forum_plural,
            icon: "op-file-comment"

  menu.push :repository,
            { controller: "/repositories", action: :show },
            if: ->(p) { p.repository && !p.repository.new_record? },
            icon: "file-directory-open-fill"

  # Wiki menu items are added by WikiMenuItemHelper

  menu.push :members,
            { controller: "/members", action: "index" },
            caption: :label_member_plural,
            before: :settings,
            icon: "people"

  menu.push :members_menu,
            { controller: "/members", action: "index" },
            parent: :members,
            partial: "members/menus/menu",
            caption: :label_member_plural

  menu.push :settings,
            { controller: "/projects/settings/general", action: :show },
            caption: :label_project_settings,
            last: true,
            icon: "gear",
            allow_deeplink: true

  project_menu_items = {
    general: { caption: :label_information_plural },
    life_cycle_steps: {
      caption: :label_project_life_cycle,
      action: :index
    },
    project_custom_fields: { caption: :label_project_attributes_plural },
    modules: { caption: :label_module_plural },
    work_packages: {
      caption: :label_work_package_plural,
      if: ->(project) {
        User.current.allowed_in_project?(:edit_project, project) ||
          User.current.allowed_in_project?(:manage_types, project) ||
          User.current.allowed_in_project?(:manage_categories, project) ||
          User.current.allowed_in_project?(:select_custom_fields, project)
      }
    },
    versions: { caption: :label_version_plural },
    repository: { caption: :label_repository },
    time_entry_activities: { caption: :enumeration_activities },
    storage: { caption: :label_required_disk_storage }
  }

  project_menu_items.each do |key, options|
    menu.push :"settings_#{key}",
              { controller: "/projects/settings/#{key}", action: "show" }.merge(options.slice(:action)),
              parent: :settings,
              **options.except(:action)
  end
end

Redmine::MenuManager.map :work_package_split_view do |menu|
  menu.push :overview,
            { tab: :overview },
            skip_permissions_check: true,
            caption: :"js.work_packages.tabs.overview"
  menu.push :activity,
            { tab: :activity },
            skip_permissions_check: true,
            badge: ->(work_package:, **) {
                     Notification.where(recipient: User.current,
                                        read_ian: false,
                                        resource: work_package)
                                 .where.not(reason: %i[date_alert_start_date date_alert_due_date])
                                 .count
                   },
            caption: :"js.work_packages.tabs.activity"
  menu.push :files,
            { tab: :files },
            skip_permissions_check: true,
            badge: ->(work_package:, **) {
              count = Storages::FileLink.where(container_type: "WorkPackage", container_id: work_package).count
              unless work_package.hide_attachments?
                count += work_package.attachments.count
              end
              count
            },
            caption: :"js.work_packages.tabs.files"
  menu.push :relations,
            { tab: :relations },
            skip_permissions_check: true,
            badge: ->(work_package:, **) {
              WorkPackageRelationsTab::RelationsMediator.new(work_package: work_package).all_relations_count
            },
            caption: :"js.work_packages.tabs.relations"
  menu.push :watchers,
            { tab: :watchers },
            skip_permissions_check: true,
            badge: ->(work_package:, **) {
              work_package.watchers.count
            },
            caption: :"js.work_packages.tabs.watchers"
end

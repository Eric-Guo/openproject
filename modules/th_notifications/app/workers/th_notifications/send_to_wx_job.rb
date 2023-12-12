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

class ThNotifications::SendToWxJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(id)
    notification = Notification.find(id)
    user = notification.recipient
    work_package = notification.resource
    project = work_package.project

    I18n.locale = user.language
    data = {}
    case ENV['WX_TEMPLATE_ID']
    when 'n2wkRHVypiIDrxrRlxctKnzdaZG7PHdbqojRqRsRm6o'
      data = {
        first: { value: '您好，您收到了一个任务动态！' },
        keyword1: { value: project.name },
        keyword2: { value: work_package.subject },
        keyword3: { value: work_package.start_date&.strftime('%Y-%m-%d') || '' },
        remark: { value: '请点击本消息查看详细信息' },
      }
    when 'JlQs66nWj_kyHsfvraJxhDoUlXGc3ECusJBu_-BmBX0'
      data = {
        first: { value: [project.name, I18n.t("js.notifications.reasons.#{API::V3::Notifications::PropertyFactory::reason_for(notification)}")].join(' - ') },
        keyword1: { value: work_package.id.to_s },
        keyword2: { value: work_package.subject },
        keyword3: { value: work_package.status&.name || '' },
        remark: { value: '请点击本消息查看详细信息' },
      }
    when 'Sf47EGjbvBe8mZoFi4J54pThnU5MPWwPTwLiZM2MVXo'
      data = {
        first: { value: [project.name, I18n.t("js.notifications.reasons.#{API::V3::Notifications::PropertyFactory::reason_for(notification)}")].join(' - ') },
        keyword1: { value: work_package.subject },
        keyword2: { value: work_package.id.to_s },
        keyword3: { value: notification.created_at&.strftime('%Y-%m-%d %H:%M:%S') || '' },
        remark: { value: '请点击本消息查看详细信息' },
      }
    end
    if data.present?
      Proto::OpService::Service.current_client.call(:SendMessage, {
        templateID: ENV['WX_TEMPLATE_ID'],
        data:,
        url: "#{ENV['WX_WORK_PACKAGE_DETAIL'].gsub(/:id(?=(\W|$))/, work_package.id.to_s)}?from=wx_template_message",
        toUserID: user.id,
      })
    end
  end
end

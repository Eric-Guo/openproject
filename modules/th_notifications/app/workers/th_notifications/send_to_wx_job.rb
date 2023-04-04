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

    Proto::OpService::Service.current_client.call(:SendMessage, {
      templateID: ENV['WX_TEMPLATE_ID'],
      data: {
        first: { value: "您好，您收到了一个新的任务动态" },
        keyword1: { value: project.name },
        keyword2: { value: work_package.subject },
        keyword3: { value: work_package.start_date&.strftime('%Y-%m-%d') || '' },
        remark: { value: '如已知晓，请忽略。' },
      },
      url: ENV['WX_WORK_PACKAGE_DETAIL'].gsub(/:id(?=(\W|$))/, work_package.id.to_s),
      toUserID: user.id,
    })
  end
end

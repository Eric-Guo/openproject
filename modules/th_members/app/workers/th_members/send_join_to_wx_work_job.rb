class ThMembers::SendJoinToWxWorkJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(id)
    member = Member.find(id)
    user = member.principal

    return unless user.mail.end_with?('@thape.com.cn')

    project = member.project

    data = {
      toUserID: user.id,
      title: '项目通知',
      description: [
        "<div class=\"highlight\">加入新项目</div>",
        "<div class=\"normal\">项目名称：#{project.name}</div>",
        "<div class=\"normal\">角色名称：#{member.roles.pluck(:name).join(',')}</div>",
      ].join(''),
      url: Rails.application.routes.url_helpers.root_url(host: Setting.host_name, protocol: Setting.protocol),
      buttonText: '详情',
    }

    Proto::OpService::Service.current_client.call(:SendWcWorkerMessage, data)
  end
end

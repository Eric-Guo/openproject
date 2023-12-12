class ThNotifications::SendToWxWorkJob < ApplicationJob
  queue_with_priority :above_normal

  def perform(id)
    notification = Notification.find(id)
    user = notification.recipient

    return unless user.mail.end_with?('@thape.com.cn')

    work_package = notification.resource
    project = work_package.project

    I18n.locale = user.language

    data = {
      toUserID: user.id,
      title: '工作通知',
      description: [
        "<div class=\"highlight\">#{I18n.t("js.notifications.reasons.#{API::V3::Notifications::PropertyFactory::reason_for(notification)}")}</div>",
        "<div class=\"normal\">工作包名：#{work_package.subject}</div>",
        "<div class=\"normal\">工作包ID：#{work_package.id}</div>",
        "<div class=\"normal\">项目名：#{project.name}</div>",
      ].join(''),
      url: "#{ENV['WX_WORK_PACKAGE_DETAIL'].gsub(/:id(?=(\W|$))/, work_package.id.to_s)}?from=wx_work_template_message",
      buttonText: '详情',
    }

    Proto::OpService::Service.current_client.call(:SendWcWorkerMessage, data)
  end
end

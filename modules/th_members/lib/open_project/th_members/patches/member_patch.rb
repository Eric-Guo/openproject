module OpenProject::ThMembers
  module Patches::MemberPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :profile, class_name: "MemberProfile", foreign_key: "member_id"

        accepts_nested_attributes_for :profile

        after_save :set_default_profile, if: Proc.new { |member| member.profile.blank? }

        after_create :send_join_notifications

        private
        def send_join_notifications
          ThMembers::SendJoinToWxWorkJob.perform_later(self.id)
        end
      end
    end

    module InstanceMethods
      def set_notification_settings
        ns = NotificationSetting.where(project_id:).where(user_id:).take || NotificationSetting.new(project_id:, user_id:)

        return unless ns.new_record?

        role_ids = roles.pluck(:id)

        # 我关注的
        ns.watched = true
        # 被@提及的
        ns.mentioned = true
        # 工作包 - 所有新评论
        ns.work_package_commented = false
        # 工作包 - 新工作包
        ns.work_package_created = false
        # 工作包 - 所有状态变更
        ns.work_package_processed = false
        # 工作包 - 所有优先级变更
        ns.work_package_prioritized = false
        # 工作包 - 所有日期变更
        ns.work_package_scheduled = false
        # 新闻 - 添加
        ns.news_added = false
        # 新闻 - 评论
        ns.news_commented = false
        # 文档 - 文档
        ns.document_added = false
        # 论坛 - 消息
        ns.forum_messages = false
        # wiki - 添加
        ns.wiki_page_added = false
        # wiki - 更新
        ns.wiki_page_updated = false
        # 成员 - 添加
        ns.membership_added = false
        # 成员 - 修改
        ns.membership_updated = false
        # 开始日期, 1: same day, 1: 1 day before, 3: 3 day before, 7: a week before
        ns.start_date = nil
        # 完成日期, 值同上
        ns.due_date = nil
        # 超时, 0: every day, 3: every 3 days, 7: every week
        ns.overdue = nil
        # 指定人
        ns.assignee = false
        # 负责人
        ns.responsible = false

        if role_ids.include?(3)
          ns.assignee = true
          ns.responsible = true
          ns.overdue = 3
          ns.work_package_created = true
          ns.work_package_processed = true
          ns.work_package_scheduled = true
        elsif role_ids.include?(4)
          ns.watched = false
          ns.assignee = true
          ns.responsible = true
        end
        ns.save!
      end

      def set_default_profile
        profile = MemberProfile.new(member_id: self.id)
        profile.save
      end
    end
  end
end

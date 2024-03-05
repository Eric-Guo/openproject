module WorkPackageEdocFiles
  class ThAnnotationDocument < ::ThAnnotationDocument
    belongs_to :edoc_file, class_name: "WorkPackageEdocFile", foreign_key: "target_id"

    def participants
      { value: self.members }.deep_transform_keys { |key| key.to_s.to_sym }[:value]
    end

    def sync_members # rubocop:disable Metrics/AbcSize
      users = edoc_file.folder.work_package.project.members.map do |member|
        {
          name: member.principal.name,
          email: member.principal.mail,
          is_internal: member.principal.mail.end_with?('@thape.com.cn')
        }
      end

      unless users == self.participants
        ThAnnotator::Apis::Base.sync_document_users(uuid:, users:)
        self.update_columns(members: users)
      end
    end
  end
end

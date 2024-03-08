module ThAnnotationDocuments::Callbacks
  class Comment < Base
    FIELDS = %i(
      id
      content
      mented_user_emails
    ).freeze

    attr_accessor(*FIELDS)

    def mented_users
      @mented_users ||= User.where(mail: mented_user_emails).all
    end

    def metions_raw
      @metions_raw ||= mented_users&.map do |user|
        <<~RAW.squish
          <mention class="mention" data-id="#{user.id}" data-type="user" data-text="#{user.name}">
            #{user.name}
          </mention>
        RAW
      end&.join
    end
  end
end

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
  end
end

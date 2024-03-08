module ThAnnotationDocuments::Callbacks
  class Annotator < Base
    FIELDS = %i(
      id
      status
      description
      specialty
      images
      mented_user_emails
    ).freeze

    attr_accessor(*FIELDS)

    def images_raw
      @images_raw ||= images&.map do |image|
        <<~RAW.squish
          <img class="op-uc-image op-uc-image_inline" style="width:100px;" src="#{image}">
        RAW
      end&.join
    end

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

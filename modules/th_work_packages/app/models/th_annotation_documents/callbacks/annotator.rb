module ThAnnotationDocuments::Callbacks
  class Annotator < Base
    FIELDS = %i(
      id
      status
      description
      specialty
      images
    ).freeze

    attr_accessor(*FIELDS)

    def images_raw
      @images_raw ||= images&.map do |image|
        <<~RAW.squish
          <img class="op-uc-image op-uc-image_inline" style="width:100px;" src="#{image}">
        RAW
      end&.join
    end
  end
end

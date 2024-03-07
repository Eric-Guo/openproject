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
  end
end

module ThAnnotationDocuments::Callbacks
  class Document < Base
    FIELDS = %i(
      uuid
      file_name
      document_type
    ).freeze

    attr_accessor(*FIELDS)

    def resource
      @resource ||= ThAnnotationDocument.find_by!(uuid:)

      unless @resource.is_a?(WorkPackageEdocFiles::ThAnnotationDocument)
        raise StandardError, 'AnnotationDocument is not WorkPackageEdocFiles::ThAnnotationDocument'
      end

      @resource
    end

    def edoc_file
      @edoc_file ||= resource.edoc_file
    end

    def edoc_folder
      @edoc_folder ||= edoc_file.folder
    end

    def work_package
      @work_package ||= edoc_folder.work_package
    end
  end
end

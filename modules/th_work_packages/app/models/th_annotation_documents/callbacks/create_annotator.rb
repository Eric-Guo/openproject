module ThAnnotationDocuments::Callbacks
  class CreateAnnotator < Base
    FIELDS = %i(
      msg_type
      from_user
      msg_id
      document
      annotator
    ).freeze

    attr_accessor(*FIELDS)

    def document=(value)
      raise ArgumentError, 'Missing document' if value.blank?

      @document = Document.new(value)
    end

    def annotator=(value)
      raise ArgumentError, 'Missing annotator' if value.blank?

      @annotator = Annotator.new(value)
    end

    def current_user
      @current_user ||= User.find_by!(mail: from_user)
    end

    def title
      '创建标注'
    end

    def raw
      <<~RAW.squish
        <p class="op-uc-p">
          <strong>#{title}</strong>
        </p>
        <p class="op-uc-p"><i>[#{annotator.specialty}]</i> #{annotator.description}</p>
        <blockquote class="op-uc-blockquote">
          <p class="op-uc-p">
            文件：
            <a class="op-uc-link" href="#{document.edoc_file.publish_preview_url}" target="_blank">
              #{document.file_name}
            </a>
          </p>
        </blockquote>
      RAW
    end

    def call
      AddWorkPackageNoteService.new(user: current_user, work_package: document.work_package)
                               .call(raw, send_notifications: true)
    end
  end
end

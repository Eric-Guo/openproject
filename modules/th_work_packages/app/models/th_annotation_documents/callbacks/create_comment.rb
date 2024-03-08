module ThAnnotationDocuments::Callbacks
  class CreateComment < Base
    FIELDS = %i(
      msg_type
      from_user
      msg_id
      document
      annotator
      comment
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

    def comment=(value)
      raise ArgumentError, 'Missing comment' if value.blank?

      @comment = Comment.new(value)
    end

    def current_user
      @current_user ||= User.find_by!(mail: from_user)
    end

    def title
      '创建评论'
    end

    def raw # rubocop:disable Metrics/AbcSize
      @raw ||= <<~RAW.squish
        <p class="op-uc-p">
          <strong>#{title}</strong>
        </p>
        <p class="op-uc-p">#{comment.content}</p>
        #{
          comment.metions_raw && \
          "<p class=\"op-uc-p\">#{comment.metions_raw}</p>"
        }
        <blockquote class="op-uc-blockquote">
          <p class="op-uc-p">
            文件：
            <a class="op-uc-link" href="#{document.edoc_file.publish_preview_url}" target="_blank">
              #{document.file_name}
            </a>
          </p>
          <p class="op-uc-p">
            标注：
            <i>
              #{
                annotator.status.present? && \
                "[#{annotator.status}] "
              }
              #{
                annotator.specialty.present? && \
                "[#{annotator.specialty}] "
              }
            </i>
            #{annotator.description}
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

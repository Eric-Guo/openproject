module API
  module Decorators
    class ProjectProfile < Single
      def initialize(model)
        super(model, current_user: nil)
      end

      property :type_id,
               exec_context: :decorator,
               getter: ->(*) { represented.type_id },
               render_nil: true
      property :name,
               exec_context: :decorator,
               getter: ->(*) { represented.name },
               render_nil: true
      property :code,
               exec_context: :decorator,
               getter: ->(*) { represented.code },
               render_nil: true
      property :doc_link,
               exec_context: :decorator,
               getter: ->(*) { represented.doc_link },
               render_nil: true
    end
  end
end

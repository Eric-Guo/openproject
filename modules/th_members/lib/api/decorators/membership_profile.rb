module API
  module Decorators
    class MembershipProfile < Single
      def initialize(model)
        super(model, current_user: nil)
      end

      property :name,
               exec_context: :decorator,
               getter: ->(*) { represented.name },
               render_nil: true
      property :company,
               exec_context: :decorator,
               getter: ->(*) { represented.company },
               render_nil: true
      property :department,
               exec_context: :decorator,
               getter: ->(*) { represented.department },
               render_nil: true
      property :position,
               exec_context: :decorator,
               getter: ->(*) { represented.position },
               render_nil: true
      property :major,
               exec_context: :decorator,
               getter: ->(*) { represented.major },
               render_nil: true
      property :mobile,
               exec_context: :decorator,
               getter: ->(*) { represented.mobile },
               render_nil: true
      property :remark,
               exec_context: :decorator,
               getter: ->(*) { represented.remark },
               render_nil: true
    end
  end
end

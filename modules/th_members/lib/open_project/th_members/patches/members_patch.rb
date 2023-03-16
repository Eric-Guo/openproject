module OpenProject::ThMembers
  module Patches::MembersPatch
    def self.mixin!
      ::Members::TableCell.add_column :company
      ::Members::TableCell.add_column :position
      ::Members::TableCell.add_column :remark
      ::Members::TableCell.options :current_user # adds current_user option

      ::MembersController.prepend TableOptions
      ::Members::TableCell.prepend TableCell
      ::Members::RowCell.prepend RowCell
    end

    module TableOptions
      def members_table_options(_roles)
        super.merge current_user:
      end
    end

    module TableCell
      def sort_collection(query, sort_clause, sort_columns)
        super(join_profiles(query), sort_clause, sort_columns)
      end

      def join_profiles(query)
        query.includes(:profile)
      end

      def columns
        if th_members_enabled?
          super # all columns including :company, :position, :remark as defined in `Members.mixin!`
        else
          super - [:company, :position, :remark]
        end
      end

      def th_members_enabled?
        if @th_members_enabled.nil?
          @th_members_enabled = project.present? && project.module_enabled?(:th_members)
        end

        @th_members_enabled
      end
    end

    module RowCell
      def company
        if show_profile?
          label = member.profile&.company.presence || '无'
          span = content_tag "span", label, id: "member-#{member.id}-company"

          if may_update?
            span + company_form_cell.call
          else
            span
          end
        end
      end

      def company_form_cell
        ::ThMembers::CompanyFormCell.new(
          member,
          row: self,
          params: controller.params,
          context: { controller: }
        )
      end

      def company_css_id
        "member-#{member.id}-company"
      end

      def position
        if show_profile?
          label = member.profile&.position.presence || '无'
          span = content_tag "span", label, id: "member-#{member.id}-position"

          if may_update?
            span + position_form_cell.call
          else
            span
          end
        end
      end

      def position_form_cell
        ::ThMembers::PositionFormCell.new(
          member,
          row: self,
          params: controller.params,
          context: { controller: }
        )
      end

      def position_css_id
        "member-#{member.id}-position"
      end

      def remark
        if show_profile?
          label = member.profile&.remark.presence || '无'
          span = content_tag "span", label, id: "member-#{member.id}-remark"

          if may_update?
            span + remark_form_cell.call
          else
            span
          end
        end
      end

      def remark_css_id
        "member-#{member.id}-remark"
      end

      def remark_form_cell
        ::ThMembers::RemarkFormCell.new(
          member,
          row: self,
          params: controller.params,
          context: { controller: }
        )
      end

      def column_css_class(name)
        if name == :company
          "company"
        elsif name == :position
          "position"
        elsif name == :remark
          "remark"
        else
          super
        end
      end

      delegate :project, to: :table

      def show_profile?
        th_members_enabled? && user? && allow_profile_view?
      end

      def th_members_enabled?
        project.present? && project.module_enabled?(:th_members)
      end

      def allow_profile_view?
        table.current_user.allowed_to? :view_th_members, project
      end
    end
  end
end

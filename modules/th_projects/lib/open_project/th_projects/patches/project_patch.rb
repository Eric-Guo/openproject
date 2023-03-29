module OpenProject::ThProjects
  module Patches::ProjectPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_one :profile, class_name: "ProjectProfile", foreign_key: "project_id"

        accepts_nested_attributes_for :profile

        after_save :set_profile

        attr_accessor :project_type_id, :project_code, :project_name, :project_doc_link

        after_initialize do |project|
          @project_type_id = project.profile&.type_id
          @project_code = project.profile&.code
          @project_name = project.profile&.name
          @project_doc_link = project.profile&.doc_link
        end
      end
    end

    module InstanceMethods
      def set_profile
        profile = self.profile || ProjectProfile.new(project_id: self.id)
        profile.type_id = project_type_id if project_type_id.present?
        profile.code = project_code if project_code.present?
        profile.name = project_name if project_name.present?
        profile.doc_link = project_doc_link if project_doc_link.present?
        profile.save! if profile.changed?
      end
    end
  end
end

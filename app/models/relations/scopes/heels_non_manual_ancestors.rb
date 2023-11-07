module Relations::Scopes
  module HeelsNonManualAncestors
    extend ActiveSupport::Concern

    class_methods do
      # Returns all follows relationships of work package ancestors or work package unless
      # the ancestor or a work package between the ancestor and self is manually scheduled.
      def heels_non_manual_ancestors(work_package)
        ancestor_relations_non_manual = WorkPackageHierarchy
                                          .where(descendant_id: work_package.id)
                                          .where.not(ancestor_id: from_manual_ancestors(work_package).select(:ancestor_id))

        where(from_id: ancestor_relations_non_manual.select(:ancestor_id))
          .heels
      end

      private

      def from_manual_ancestors(work_package)
        manually_schedule_ancestors = work_package.ancestors.where(schedule_manually: true)

        WorkPackageHierarchy
          .where(descendant_id: manually_schedule_ancestors.select(:id))
      end
    end
  end
end

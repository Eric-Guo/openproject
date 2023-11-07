class Queries::WorkPackages::Filter::PreheelsFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include ::Queries::WorkPackages::Filter::FilterOnDirectedRelationsMixin

  def relation_type
    ::Relation::TYPE_PREHEELS
  end

  private

  def relation_filter
    { from_id: values }
  end

  def relation_select
    :to_id
  end
end

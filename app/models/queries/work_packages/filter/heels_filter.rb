class Queries::WorkPackages::Filter::HeelsFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  include ::Queries::WorkPackages::Filter::FilterOnDirectedRelationsMixin

  def relation_type
    ::Relation::TYPE_HEELS
  end

  def human_name
    I18n.t("query_fields.heels")
  end

  private

  def relation_filter
    { to_id: values }
  end

  def relation_select
    :from_id
  end
end

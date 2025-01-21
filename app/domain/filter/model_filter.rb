class ModelFilter
  extend ActiveSupport::Concern

  attr_reader :group, :user, :accessibles, :chain, :filter_scope

  def initialize(chain, filter_scope)
    @chain = chain
    @filter_scope = filter_scope
  end

  def filter_all(group, current_user, accessibles)
    @group = group
    @user = current_user
    @accessibles = accessibles
    filtered_accessibles.preload_groups.distinct
  end

  def filtered_accessibles
    filtered = filter_with_selection.unscope(:select).select(:id).distinct
    accessibles.where(id: filtered)
  end

  def filter_with_selection
    @ids.present? ? filter.where(id: @ids) : filter
  end

  def filter
    # When not filtering, the default is to exclude all passive and external people,
    # i.e. include only members
    if chain.present?
      chain.filter(filter_scope)
    else
      filter_scope.where(roles: {archived_at: nil})
                .or(filter_scope.where(Role.arel_table[:archived_at].gt(Time.now.utc)))
                .members
    end
  end

  def required_abilities
    chain.required_abilities
  end
end

class ModelFilter
  extend ActiveSupport::Concern

  attr_reader :accessibles, :chain, :filter_scope

  def initialize(chain, filter_scope, accessibles)
    @chain = chain
    @filter_scope = filter_scope
    @accessibles = accessibles
  end

  def filtered_results
    filtered_accessibles.preload_groups.distinct
  end

  def filtered_accessibles
    accessibles.where(id: filter.distinct)
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
end

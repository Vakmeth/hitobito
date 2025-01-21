class ModelFilter
  extend ActiveSupport::Concern

  attr_reader :type, :filter_id, :range, :name, :group, :user, :accessibles, :chain

  def initialize(type, parameters)
    @type = type
    @filter_id = parameters[:filter_id]
    @range = parameters[:range]
    @name = parameters[:name]
    if type == FilterType::PERSON
      @chain = Person::Filter::Chain.new(get_filter_params(filter_id, parameters))
    end
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

  def group_range?
    !%w[deep layer].include?(range)
  end

  def filter
    # When not filtering, the default is to exclude all passive and external people,
    # i.e. include only members

    if chain.present?
      chain.filter(list_range)
    else
      list_range.where(roles: {archived_at: nil})
                .or(list_range.where(Role.arel_table[:archived_at].gt(Time.now.utc)))
                .members
    end
  end

  def list_range
    case range
    when "deep"
      Person.in_or_below(group, chain.roles_join)
    when "layer"
      Person.in_layer(group, join: chain.roles_join)
    else
      Person.in_group(group, chain.roles_join)
    end
  end

  def get_filter_params(filter_id, params)
    if filter_id.nil?
      return params[:filters]
    end
    PeopleFilter.find(params[:filter_id]).to_params
  end
end

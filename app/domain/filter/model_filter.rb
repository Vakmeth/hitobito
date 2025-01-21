class ModelFilter
  extend ActiveSupport::Concern

  attr_reader :type, :filter_id, :group, :user, :range, :name, :accessibles, :chain

  def initialize(type, filter_id)
    @type = type
    @filter_id = filter_id
  end

  def filter_all(parameters, group, current_user, accessibles)
    @group = group
    @user = current_user
    @range = parameters[:range]
    @name = parameters[:name]
    @accessibles = accessibles
    if type == FilterType::PERSON
      filter_params = get_filter_params(filter_id, parameters)
      @chain = Person::Filter::Chain.new(filter_params)
      filtered_accessibles.preload_groups.distinct
    end
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

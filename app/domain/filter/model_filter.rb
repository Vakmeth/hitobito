class ModelFilter
  extend ActiveSupport::Concern

  attr_reader :type, :range, :group, :user, :accessibles, :chain, :name

  def initialize(type=FilterType::PERSON, parameters={})
    @type = type
    @range = parameters[:range]
    if type == FilterType::PERSON
      @name = parameters[:name]
      @chain = Person::Filter::Chain.new(get_filter_params(parameters))
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

  def get_filter_params(params)
    filter_id = params[:filter_id]
    if filter_id.nil?
      return params[:filters]
    end
    @name = PeopleFilter.find(filter_id).name
    PeopleFilter.find(filter_id).to_params[:filters]
  end

  def required_abilities
    chain.required_abilities
  end
end

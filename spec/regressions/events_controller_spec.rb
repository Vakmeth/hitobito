# encoding: UTF-8
require 'spec_helper'

describe EventsController, type: :controller do
  
  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { ev = events(:top_course); ev.dates.clear; ev }
  let(:group) { test_entry.groups.first }
  let(:date)  {{ label: 'foo', start_at_date: Date.today, finish_at_date: Date.today }}
  let(:test_entry_attrs) { { name: 'Chief Leader Course', group_ids: [group.id], dates_attributes: [ date ] } }

  let(:scope_params) { {group_id: group.id} }
  
  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(index),%w(new)]

  def deep_attributes(*args)
    { name: "Chief Leader Course", dates_attributes: [date], group_ids: [group.id]}  
  end

  describe "GET #index" do
    render_views
    let(:group) { groups(:top_group) }
    let(:dom) { Capybara::Node::Simple.new(response.body) } 
    let(:today) { Date.today }
    let(:last_year) { 1.year.ago }

    it "renders dropdown to add new events" do
      get :index, group_id: group.id
      dom.find('.dropdown-toggle').text.should include 'Anlass erstellen'
      [Event, Event::Course].each_with_index do |item, index|
        path = new_group_event_path(event: {type: item.sti_name})
        dom.all('.dropdown-menu a')[index].text.should eq item.model_name.human
        dom.all('.dropdown-menu a')[index][:href].should eq path
      end
    end

    it "lists entries for current year" do
      ev = event_with_date(start_at: today)
      event_with_date(start_at: last_year)
      get :index, group_id: group.id
      dom.all('#main table tr').count.should eq 1
      dom.find('#main table tr').text.should include ev.name
      dom.find_link(today.year.to_s).native.parent[:class].should eq 'active'
    end

    it "pages per year" do
      event_with_date(start_at: today)
      ev = event_with_date(start_at: last_year)
      get :index, group_id: group.id, year: last_year.year
      dom.all('.pagination li').count.should eq 5
      dom.all('#main table tr').count.should eq 1
      dom.find('#main table tr').text.should include ev.name
      dom.find_link(last_year.year.to_s).native.parent[:class].should eq 'active'
    end

    def event_with_date(opts = {})
      opts = {groups: [group], state: 'application_open', start_at: Date.today}.merge(opts)
      event = Fabricate(:event, groups: opts[:groups], state: opts[:state])
      set_start_dates(event, opts[:start_at])
      event
    end
  end

  describe "GET #new" do
    render_views
    let(:group) { groups(:top_group) }
    let(:dom) { Capybara::Node::Simple.new(response.body) } 
    
    it "renders new form" do
      get :new, group_id: group.id, event: {type: 'Event'}
      dom.find('input#event_type')[:type].should eq 'hidden'
      dom.all('#questions_fields .fields').count.should eq 3
      dom.all('#dates_fields').count.should eq 1
    end
  end

end

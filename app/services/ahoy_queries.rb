module AhoyQueries
  module_function

  YESTERDAY = "Yesterday"
  LAST_7_DAYS = "Last 7 Days"
  LAST_30_DAYS = "Last 30 Days"
  LAST_MONTH = "Last Month"
  LAST_QUARTER = "Last Quarter"
  LAST_12_MONTHS = "Last 12 Months"

  DATE_RANGE_OPTIONS = [
    YESTERDAY,
    LAST_7_DAYS,
    LAST_30_DAYS,
    LAST_MONTH,
    LAST_QUARTER,
    LAST_12_MONTHS,
  ]

  def get_number_of_updates_last_thirty_days(location_id)
    interval = interval_by_date_range(LAST_30_DAYS)
    Ahoy::Event.where(name: 'Location Update', properties: {id: location_id}, time: interval).count
  end

  def interval_by_date_range(date_range)
    today = Date.current.to_time(:utc).beginning_of_day
    yesterday_end = Date.yesterday.to_time(:utc).end_of_day

    case date_range
    when YESTERDAY
      (Date.yesterday.to_time(:utc).beginning_of_day..yesterday_end)
    when LAST_7_DAYS
      ((today - 8.days)..yesterday_end)
    when LAST_30_DAYS
      ((today - 31.days)..yesterday_end)
    when LAST_MONTH
      last_month = today.prev_month
      (last_month.beginning_of_month..last_month.end_of_month)
    when LAST_QUARTER
      prev_quarter = today.prev_quarter
      (prev_quarter.beginning_of_quarter..prev_quarter.end_of_quarter)
    when LAST_12_MONTHS
      ((today.prev_year)..yesterday_end)
    else
      #not valid date range
    end
  end


  def get_location_visit_events(location_id: , date_range:)
    Ahoy::Event
      .where(name: 'Location Visit', time: interval_by_date_range(date_range))
      .where(properties: {id: location_id})
      .count
  end


  def get_total_homepage_views
    Ahoy::Event
      .where(name: 'Homepage Visit')
      .count
  end


  def get_new_homepage_views(date_range:)
    Ahoy::Event
      .where(name: 'Homepage Visit', time: date_range)
      .count
  end


  def get_total_number_of_visits(date_range = LAST_7_DAYS)
    Ahoy::Visit
      .where(started_at: interval_by_date_range(date_range))
      .count
  end

  def get_total_number_of_searches(date_range = LAST_7_DAYS)
    Ahoy::Event
      .where(name: 'Perform Search', time: interval_by_date_range(date_range))
      .count
  end


  def get_avg_number_searches_per_visit_with_searches(date_range = LAST_7_DAYS)
    total_searches = get_total_number_of_searches
    total_visits = get_total_number_of_visits_with_searches

    total_searches/total_visits
  end

  def get_number_of_visits_initiated_from_homepage(date_range = LAST_7_DAYS)
    all_visits_ids =
      Ahoy::Event
        .where(time: interval_by_date_range(date_range))
        .group(:visit_id)
        .count

    visits_from_homepage = 0

    all_visits_ids.each_key do |visit_id|
      first_event_in_visit = Ahoy::Event.where(visit_id: visit_id).first

      if first_event_in_visit['name'] == 'Homepage Visit'
        visits_from_homepage += 1
      end
    end

    visits_from_homepage
  end


  def get_most_visited_locations(limit, date_range = LAST_7_DAYS)
    Ahoy::Event
      .where(name: 'Location Visit', time: interval_by_date_range(date_range))
      .group("properties -> 'id'")
      .order('COUNT(id) DESC')
      .limit(limit)
      .count
  end


  def get_most_used_keywords(limit, date_range = LAST_7_DAYS)
    most_used_keywords =
      Ahoy::Event
        .where(name: 'Perform Search', time: interval_by_date_range(date_range))
        .group("properties -> 'keywords'")
        .order('COUNT(id) DESC')
        .limit(limit)
        .count
  end


  def determine_origin_of_location_visit(location_id, date_range = LAST_7_DAYS)
    # get all Location Visit events for the given location id
    visit_events_for_location_id = get_location_visit_events(location_id)

    # get the Perform Search event immediately before the Location Visit
    preceding_search_events =
      visit_events_for_location_id.map do |event|
        get_search_event_preceding_location_visit(
          event_id: event.id,
          visit_id: event.visit_id) || nil
    end

    preceding_search_events
  end


  def get_keywords_from_search_events(search_events)
    keywords_list = []
    search_events.each do |event_id|
      next if event_id.nil?
      keywords_list << get_search_events_keywords(event_id)
    end

    keywords_list
  end


  #######################
  #  auxiliary methods
  #######################

  def get_total_number_of_visits_with_searches(date_range = LAST_7_DAYS)
    total_visits_with_searches =
      Ahoy::Event
        .where(name: 'Perform Search', time: interval_by_date_range(date_range))
        .group(:visit_id)
        .count

    total_visits_with_searches.length
  end


  def get_location_visit_events(location_id, date_range = LAST_7_DAYS)
    Ahoy::Event
      .where(name: 'Location Visit', time: interval_by_date_range(date_range))
      .where(properties: {id: location_id})
      .all
  end


  def get_search_event_preceding_location_visit(event_id:, visit_id:)
    preceding_search_event =
      Ahoy::Event
        .where(name: 'Perform Search')
        .where(visit_id: visit_id)
        .where("id < ?", event_id)
        .last

    search_event_id = preceding_search_event.nil? ? nil : preceding_search_event.id
  end


  def get_search_events_keywords(event_id)
    Ahoy::Event
      .where(id: event_id)
      .last
      .properties['keywords']
  end
end

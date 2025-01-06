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

  def get_visits_by_location_and_date_range(location_id: , date_range:)
    Ahoy::Event.where(name: 'Location Visit', properties: {id: location_id}, time: interval_by_date_range(date_range)).count
  end

  def interval_by_date_range(date_range)
    today = Date.current.to_time(:utc).beginning_of_day
    yesterday_end = Date.yesterday.to_time(:utc).end_of_day

    case date_range
    when YESTERDAY
      (Date.yesterday.to_time(:utc).beginning_of_day..yesterday_end)
    when LAST_7_DAYS
      ((today - 7.days)..today.end_of_day)
    when LAST_30_DAYS
      ((today - 30.days)..today.end_of_day)
    when LAST_MONTH
      last_month = today.prev_month
      (last_month.beginning_of_month..last_month.end_of_month)
    when LAST_QUARTER
      prev_quarter = today.prev_quarter
      (prev_quarter.beginning_of_quarter..prev_quarter.end_of_quarter)
    when LAST_12_MONTHS
      ((today.prev_year)..today.end_of_day)
    else
      #not valid date range
    end
  end

  def get_total_homepage_views
    Ahoy::Event.where(name: 'Homepage Visit').count
  end

  def get_new_homepage_views(date_range:)
    Ahoy::Event.
      where(name: 'Homepage Visit', time: date_range).count
  end

  def get_total_number_of_visits_last_seven_days
    Ahoy::Visit.where(started_at: interval_by_date_range(LAST_7_DAYS)).count
  end

  def get_total_number_of_visits_with_searches_last_seven_days
    total_visits_with_searches =
      Ahoy::Event
        .where(name: 'Perform Search', time: interval_by_date_range(LAST_7_DAYS))
        .group(:visit_id)
        .count

    total_visits_with_searches.length
  end

  def get_total_number_of_searches_last_seven_days
    Ahoy::Event
      .where(name: 'Perform Search', time: interval_by_date_range(LAST_7_DAYS)).count
  end

  def get_avg_number_searches_per_visit_with_searches_last_seven_days
    total_searches = get_total_number_of_searches_last_seven_days
    total_visits = get_total_number_of_visits_with_searches_last_seven_days

    total_searches/total_visits
  end

  def get_most_visited_locations_last_seven_days(limit)
      Ahoy::Event
        .where(name: 'Location Visit', time: interval_by_date_range(LAST_7_DAYS))
        .group("properties -> 'id'")
        .order('COUNT(id) DESC')
        .limit(limit)
        .count
  end

  def get_most_used_keywords_last_seven_days(limit)
    Ahoy::Event
      .where(name: 'Perform Search', time: interval_by_date_range(LAST_7_DAYS))
      .group("properties -> LOWER('keywords') ")
      .order('COUNT(id) DESC')
      .limit(limit)
      .count
  end

  def get_search_details_leading_to_location_visit_last_seven_days(location_id)
    events_for_location_id =
      self.get_events_for_location_id_last_seven_days(location_id)

    search_keywords = []
    events_for_location_id.each do |event|
      search_keywords << get_search_keywords(event)
    end

    count_and_sort_unique_keywords(search_keywords)
  end


  #######################
  #  auxiliary methods
  #######################

  def get_name_location(location_id)
    Location.where(id: id).last.name
  end

  def get_events_for_location_id_last_seven_days(location_id)
    Ahoy::Event
      .where(name: 'Location Visit', time: interval_by_date_range(LAST_7_DAYS))
      .where(properties: {id: location_id})
      .all
  end

  def get_last_search_event_before_location_visit(event_id:, visit_id:)
    Ahoy::Event
      .where(name: 'Perform Search', time: interval_by_date_range(LAST_7_DAYS))
      .where(visit_id: visit_id)
      .where("id < ?", event_id)
      .last
  end

  def get_search_keywords(event)
    search_details =
      get_last_search_event_before_location_visit(
        event_id: event.id,
        visit_id: event.visit_id)

    keywords =
      if search_details
        search_details.properties['keywords']
      else
        "Not from search results page"
      end
  end

  def count_and_sort_unique_keywords(search_keywords)
    distinct_keywords = search_keywords.to_set

    keywords_and_count = {}
    distinct_keywords.each do |keyword|
      keywords_and_count[keyword] = search_keywords.count(keyword)
    end

    keywords_and_count.sort_by { |_, value| -value }.to_h
  end
end

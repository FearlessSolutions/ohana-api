class Admin
  module AnalyticsHelper
    def date_range(start_date, end_date)
      start_date.beginning_of_day..end_date.end_of_day
    end

    # database figures
    def organizations_count
      total_orgs = "#{Organization.all.count}"
      total_orgs.html_safe
    end

    def new_org_count(start_date, end_date)
      new_orgs =
        "#{Organization
            .where(created_at: date_range(start_date, end_date))
            .count}"
      new_orgs.html_safe
    end

    def locations_count
      total_locations = "#{Location.all.count}"
      total_locations.html_safe
    end

    def new_location_count(start_date, end_date)
      new_locations =
        "#{Location
            .where(created_at: date_range(start_date, end_date))
            .count}"
      new_locations.html_safe
    end

    def services_count
      total_services = "#{Service.all.count}"
      total_services.html_safe
    end

    def new_service_count(start_date, end_date)
      new_services =
        "#{Service
          .where(created_at: date_range(start_date, end_date))
          .count}"
      new_services.html_safe
    end

    # homepage visits figures
    def total_homepage_views
      count_homepage_views = "#{AhoyQueries.get_total_homepage_views}"
      count_homepage_views.html_safe
    end

    def new_homepage_views(start_date, end_date)
      new_homepage_views =
        "#{AhoyQueries.get_new_homepage_views(date_range: date_range(start_date, end_date))}"
      new_homepage_views.html_safe
    end

    # search related figures
    def total_number_of_visits
      total_visits = "#{AhoyQueries.get_total_number_of_ahoy_visits}"
      total_visits.html_safe
    end

    def total_number_of_searches
      total_searches = "#{AhoyQueries.get_total_number_of_searches}"
      total_searches.html_safe
    end

    def avg_number_searches_per_visit
      avg_searches_per_visit =
        "#{AhoyQueries.get_total_number_of_searches
        .div(AhoyQueries.get_total_number_of_ahoy_visits)}"
      avg_searches_per_visit.html_safe
    end

    def number_of_visits_initiated_from_homepage
      visits_initiated_from_homepage =
        "#{AhoyQueries.get_number_of_visits_initiated_from_homepage}"
      visits_initiated_from_homepage.html_safe
    end

    def most_used_keywords
      AhoyQueries.get_most_used_keywords(10)
    end

    # calculates the average rating for the given keyword (includes only rated searches)
    def get_average_search_rating(keyword)
      all_rated_search_events = AhoyQueries.get_all_rated_search_events_for_keyword(keyword)

      sum_ratings = all_rated_search_events.reduce(0) { |sum, num| sum + num.properties['rating'] }

      number_of_rated_events = all_rated_search_events.length
      average_rating =
        if number_of_rated_events.zero?
          0
        else
          sum_ratings/number_of_rated_events
        end

      [average_rating, number_of_rated_events]
    end

    def number_of_searches_for_rating(rating)
      total_searches_for_rating =
        "(#{AhoyQueries.get_number_of_searches_for_rating(rating)} ratings)"

      total_searches_for_rating.html_safe
    end

    # retrieves all the search events for the given rating
    def searches_for_rating(rating)
      searches_with_rating = AhoyQueries.get_search_events_for_rating(rating)

      group_keywords_and_count(searches_with_rating)
    end

    # returns a breakdown of the searches with the given keyword rated with the given rating
    def keyword_search_rating_details(keyword, rating)
      keyword_searches_with_rating = AhoyQueries.get_keyword_search_rating_details(keyword, rating)

      keyword_search_breakdown = {}
      keyword_searches_with_rating.each do |search|
        # get the main category
        main_category = search.properties['main_category']
        main_category = '--' if main_category.empty?

        # check if any subcategory was applied to the search
        subcategories = search.properties['subcategories'].empty? ? "No" : "Yes"

        # create a hashmap entry with the main category and 'Yes' or 'No' to indicate the use of subcategories,
        # which allows to group and count the different ways the same keyword was used in searches
        grouping = "#{main_category}_#{subcategories}"

        keyword_search_breakdown[grouping] =
          if keyword_search_breakdown[grouping]
            keyword_search_breakdown[grouping] + 1
          else
            1
          end
      end

      keyword_search_breakdown.sort_by { |_, value| -value }[0..5]
    end

    def most_visited_locations
      AhoyQueries.get_most_visited_locations(5)
    end

    def origin_of_location_visit(location_id)
      preceding_search_events =
        AhoyQueries.determine_origin_of_location_visit(location_id)
    end

    def views_from_keyword_searches(events)
      "#{events.select{|x| !x.nil?}.length}".html_safe
    end

    def views_from_direct_links(events)
      "#{events.count(nil)}".html_safe
    end

    def top_keywords_and_count(location_visit_origin_events)
      return ''.html_safe if location_visit_origin_events.empty?

      search_keywords =
        AhoyQueries.get_keywords_from_search_events(location_visit_origin_events)

      keywords_and_count = count_and_sort_unique_keywords(search_keywords)

      # limit the results to the top 3 keywords
      keywords = keywords_and_count.keys.slice(0, 3)

      display = "<ul>"
      keywords.each do |keyword|
        keyword_count = keywords_and_count[keyword]
        keyword = "<em>[no search keywords]</em>" if keyword == ''
        display += "<li> #{keyword} (#{keyword_count})</li>"
      end

      if keywords_and_count.length > 3
        other_keyword_searches = keywords_and_count.values.sum - keywords_and_count.values.slice(0, 3).sum
        display += "<li><em>[all others]</em> (#{other_keyword_searches})</li>"
      end

      display += "</ul>"
      display.html_safe
    end

    def get_location_name(location_id)
      location_name =
        "<strong>#{Location.find(location_id).name}</strong>"
      location_name.html_safe
    end

    def group_keywords_and_count(search_events)
      keywords_list = []

      search_events.each do |event|
        keywords_list << event.properties['keywords']
      end

      keywords_and_count = count_and_sort_unique_keywords(keywords_list)
    end

    def count_and_sort_unique_keywords(search_keywords)
      distinct_keywords = search_keywords.to_set

      keywords_and_count = {}
      distinct_keywords.each do |keyword|
        keywords_and_count[keyword] = search_keywords.count(keyword)
      end

      # sort keywords by descending number of counts
      keywords_and_count.sort_by { |_, value| -value }.to_h
    end
  end
end

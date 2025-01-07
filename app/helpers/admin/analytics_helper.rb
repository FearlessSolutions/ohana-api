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
      new_orgs = "#{Organization.where(created_at: date_range(start_date, end_date)).count}"
      new_orgs.html_safe
    end

    def locations_count
      total_locations = "#{Location.all.count}"
      total_locations.html_safe
    end

    def new_location_count(start_date, end_date)
      new_locations = "#{Location.where(created_at: date_range(start_date, end_date)).count}"
      new_locations.html_safe
    end

    def services_count
      total_services = "#{Service.all.count}"
      total_services.html_safe
    end

    def new_service_count(start_date, end_date)
      new_services = "#{Service.where(created_at: date_range(start_date, end_date)).count}"
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
      total_visits = "#{AhoyQueries.get_total_number_of_visits_last_seven_days}"
      total_visits.html_safe
    end

    def total_number_of_searches
      total_searches = "#{AhoyQueries.get_total_number_of_searches_last_seven_days}"
      total_searches.html_safe
    end

    def number_of_visits_started_on_homepage
      visits_started_on_homepage =
        "#{AhoyQueries.get_number_of_visits_started_on_homepage_last_seven_days}"
      visits_started_on_homepage.html_safe
    end

    def most_visited_locations
      AhoyQueries.get_most_visited_locations_last_seven_days(5)
    end

    def most_used_keywords
      AhoyQueries.get_most_used_keywords_last_seven_days(10)
    end

    def avg_number_searches_per_visit_with_searches
      avg_searches_per_visit =
        "#{AhoyQueries.get_avg_number_searches_per_visit_with_searches_last_seven_days}"
      avg_searches_per_visit.html_safe
    end

    def search_details_leading_to_location_visit(location_id)
      AhoyQueries
        .get_search_details_leading_to_location_visit_last_seven_days(location_id, 3)
    end

    def get_location_name(location_id)
      location_name =
        "<strong>#{Location.where(id: location_id).last.name}</strong>"
      location_name.html_safe
    end
  end
end

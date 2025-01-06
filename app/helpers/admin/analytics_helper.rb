class Admin
  module AnalyticsHelper
    def date_range(start_date, end_date)
      start_date.beginning_of_day..end_date.end_of_day
    end

    # database figures
    def organizations_count
      total_orgs = "<td>#{Organization.all.count}</td>"
      total_orgs.html_safe
    end

    def new_org_count(start_date, end_date)
      new_orgs = "<td>#{Organization.where(created_at: date_range(start_date, end_date)).count}</td>"
      new_orgs.html_safe
    end

    def locations_count
      total_locations = "<td>#{Location.all.count}</td>"
      total_locations.html_safe
    end

    def new_location_count(start_date, end_date)
      new_locations = "<td>#{Location.where(created_at: date_range(start_date, end_date)).count}</td>"
      new_locations.html_safe
    end

    def services_count
      total_services = "<td>#{Service.all.count}</td>"
      total_services.html_safe
    end

    def new_service_count(start_date, end_date)
      new_services = "<td>#{Service.where(created_at: date_range(start_date, end_date)).count}</td>"
      new_services.html_safe
    end


    # homepage visits figures
    def total_homepage_views
      count_homepage_views = "<td>#{AhoyQueries.get_total_homepage_views}</td>"
      count_homepage_views.html_safe
    end

    def new_homepage_views(start_date, end_date)
      new_homepage_views =
        "<td>
          #{AhoyQueries.get_new_homepage_views(date_range: date_range(start_date, end_date))}
        </td>"
      new_homepage_views.html_safe
    end


    # search related figures
    def total_number_of_visits
      total_visits = "<td>#{AhoyQueries.get_total_number_of_visits_last_seven_days}</td>"
      total_visits.html_safe
    end

    def total_number_of_searches
      total_searches = "<td>#{AhoyQueries.get_total_number_of_searches_last_seven_days}</td>"
      total_searches.html_safe
    end

    def most_visited_locations
      AhoyQueries.get_most_visited_locations_last_seven_days(5)
    end

    def most_used_keywords
      AhoyQueries.get_most_used_keywords_last_seven_days(10)
    end

    def avg_number_searches_per_visit_with_searches
      avg_searches_per_visit =
        "<td>#{
          AhoyQueries.get_avg_number_searches_per_visit_with_searches_last_seven_days}
        </td>"
      avg_searches_per_visit.html_safe
    end

    def search_details_leading_to_location_visit(location_id)
      AhoyQueries
        .get_search_details_leading_to_location_visit_last_seven_days(location_id)
    end

    def get_location_name(location_id)
      location_name = "<td>#{Location.where(id: location_id).last.name}</td>"
      location_name.html_safe
    end
  end
end

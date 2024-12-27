class Admin
  module AnalyticsHelper
    def date_range(start_date, end_date)
      start_date.beginning_of_day..end_date.end_of_day
    end

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

    def total_homepage_views(landing_page)
      count_homepage_views = "<td>#{AhoyQueries.get_total_homepage_views(landing_page: landing_page)}</td>"
      count_homepage_views.html_safe
    end

    def new_homepage_views(landing_page, start_date, end_date)
      new_homepage_views =
        "<td>#{AhoyQueries.get_new_homepage_views(landing_page: landing_page,
                                                  date_range: date_range(start_date, end_date))}</td>"
      new_homepage_views.html_safe
    end
  end
end

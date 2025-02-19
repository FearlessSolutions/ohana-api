module AhoyEventsHelper
  def fire_homepage_view_event
    ahoy.track("Homepage Visit")
  end

  def fire_location_view_event
    ahoy.track("Location Visit", id: @location.id)
  end

  def fire_location_update_event
    ahoy.track("Location Update", id: @location.id)
  end

  def fire_perform_search_event
    keyword = params[:keyword]
    keyword = keyword.present? ? keyword.downcase : ""
    ahoy.track("Perform Search",
               keywords: keyword,
               main_category: @main_category_selected_name,
               subcategories: @selected_categories,
               results: @search.locations.total_count,
               rating: 0)

    # save current ahoy visit id to session
    session[:visit_id] = AhoyQueries.get_visit_id_of_most_recent_search_event
  end
end

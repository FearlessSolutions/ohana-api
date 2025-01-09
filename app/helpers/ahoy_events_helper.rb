module AhoyEventsHelper
  def fire_location_view_event
    ahoy.track("Location Visit", id: @location.id)
  end

  def fire_location_update_event
    ahoy.track("Location Update", id: @location.id)
  end

  def fire_perform_search_event
    ahoy.track( "Perform Search",
                keywords: params[:keyword],
                main_category: @main_category_selected_name,
                subcategories: @selected_categories,
                results: @search.locations.total_count)
  end
end

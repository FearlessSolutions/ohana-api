module AhoyEventsHelper
  def fire_homepage_view_event
    ahoy.track("Homepage Visit")
  end

  def fire_location_view_event
    ahoy.track("Location Visit", id: @location.id)
  end

  def fire_location_edit_event
  end

  def fire_perform_search_event
    ahoy.track( "Perform Search",
                keywords: params[:keyword].downcase,
                main_category: @main_category_selected_name,
                subcategories: @selected_categories,
                results: @search.locations.total_count)
  end
end

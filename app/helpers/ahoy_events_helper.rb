module AhoyEventsHelper
  def fire_location_view_event
    ahoy.track("Location Visit", id: @location.id)
  end

  def fire_location_update_event
    ahoy.track("Location Update", id: @location.id)
  end
end

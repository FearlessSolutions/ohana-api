module AhoyEventsHelper
  def fire_location_view_event
    ahoy.track("Location Visit", id:"#{@location.id}")
  end

  def fire_location_edit_event
  end
end
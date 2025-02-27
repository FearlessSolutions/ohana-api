class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.geocode = false

# set the duration of a single Ahoy visit
Ahoy.visit_duration = 12.hours

# allow RSpec testing of Ahoy tracking
Ahoy.track_bots = Rails.env.test?

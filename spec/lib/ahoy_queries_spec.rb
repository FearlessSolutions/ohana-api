require 'rails_helper'

describe AhoyQueries do
  describe "#get_visits_by_location_and_date_range" do

    before do
      ahoy = Ahoy::Tracker.new
      @location = create(:location)
      ahoy.track("Location Visit", id: @location.id)
    end

    it "returns the right amount of visits when date range is 'Yesterday'" do
      date_range = AhoyQueries::YESTERDAY
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.day.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 7 Days'" do
      date_range = AhoyQueries::LAST_7_DAYS
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.day.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 30 Days'" do
      date_range = AhoyQueries::LAST_30_DAYS
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.day.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last Month'" do
      date_range = AhoyQueries::LAST_MONTH
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.month.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last Quarter'" do
      date_range = AhoyQueries::LAST_QUARTER
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: Date.current.prev_quarter - 1.day)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 12 Months'" do
      date_range = AhoyQueries::LAST_12_MONTHS
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.day.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_visits_by_location_and_date_range(location_id: @location.id, date_range: date_range)
      expect(visits).to eq(1)
    end
  end
end

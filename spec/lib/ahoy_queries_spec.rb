require 'rails_helper'

describe AhoyQueries do
  describe "#get_total_visits_by_location_and_date_range" do
    before do
      ahoy = Ahoy::Tracker.new
      @location = create(:location)
      ahoy.track("Location Visit", id: @location.id)
    end

    it "returns the right amount of visits when date range is 'Yesterday'" do
      date_range = AhoyQueries::YESTERDAY
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: Date.yesterday)
      ahoy_entry.reload

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 7 Days'" do
      date_range = AhoyQueries::LAST_7_DAYS
      move_date_back_last_ahoy_event(2)

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 30 Days'" do
      date_range = AhoyQueries::LAST_30_DAYS
      move_date_back_last_ahoy_event(2)

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last Month'" do
      date_range = AhoyQueries::LAST_MONTH
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: 1.month.ago)
      ahoy_entry.reload

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last Quarter'" do
      date_range = AhoyQueries::LAST_QUARTER
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(time: Date.current.prev_quarter - 1.day)
      ahoy_entry.reload

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end

    it "returns the right amount of visits when date range is 'Last 12 Months'" do
      date_range = AhoyQueries::LAST_12_MONTHS
      move_date_back_last_ahoy_event(2)

      visits = AhoyQueries.get_total_visits_by_location_and_date_range(@location.id, date_range)
      expect(visits).to eq(1)
    end
  end

  describe "#get_number_of_updates_last_thirty_days" do
    before do
      ahoy = Ahoy::Tracker.new
      ahoy.track("Location Update", id: 1)
      move_date_back_last_ahoy_event(5)

      ahoy.track("Location Update", id: 1)
      move_date_back_last_ahoy_event(3)
    end

    it "returns the correct number of updates for a given location in the last thirty days" do
      number_of_updates = AhoyQueries.get_number_of_updates_last_thirty_days(1)
      expect(number_of_updates).to eq(2)
    end
  end

  describe "#get_total_number_of_ahoy_visits" do
    before do
      first_ahoy_visit = Ahoy::Visit.create
      first_ahoy_visit.update(started_at: 2.days.ago)

      second_ahoy_visit = Ahoy::Visit.create
      second_ahoy_visit.update(started_at: 2.days.ago)
    end

    it "returns the correct total number of ahoy visits in the last 7 days" do
      total_number_ahoy_visits = AhoyQueries.get_total_number_of_ahoy_visits

      expect(total_number_ahoy_visits).to eq(2)
    end
  end

  describe "#get_total_number_of_searches " do
    before do
      ahoy = Ahoy::Tracker.new
      ahoy.track("Location Visit", id: 1)
      move_date_back_last_ahoy_event(2)

      for i in 0..2 do
        ahoy.track("Perform Search", keywords: "")
        move_date_back_last_ahoy_event(2)
      end
    end

    it "returns the correct total number of searches in the last 7 days" do
      total_number_searches = AhoyQueries.get_total_number_of_searches

      expect(total_number_searches).to eq(3)
    end
  end

  describe "#get_number_of_visits_initiated_from_homepage" do
    before do
      @ahoy = Ahoy::Tracker.new
      @ahoy.track("Location Visit", id: 1)
      move_date_back_last_ahoy_event(2)
    end

    it "returns the accurate number of visits started from homepage in the last 7 days" do
      visits_from_homepage = AhoyQueries.get_number_of_visits_initiated_from_homepage
      expect(visits_from_homepage).to eq(0)

      # add event in visit that starts in homepage
      @ahoy.track("Homepage Visit")
      move_date_back_last_ahoy_event(2)
      ahoy_entry = Ahoy::Event.last
      ahoy_entry.update(visit_id: 2)
      ahoy_entry.reload

      visits_from_homepage = AhoyQueries.get_number_of_visits_initiated_from_homepage
      expect(visits_from_homepage).to eq(1)
    end
  end

  describe "#most_used_keywords" do
    before do
      ahoy = Ahoy::Tracker.new
      @keywords = ["", "food", "dental care", "shelter", "baby diapers", "housing"]
      @keywords.each_with_index do |keyword, n_times|
        for i in 0..(n_times) do
          ahoy.track("Perform Search", keywords: keyword)
          move_date_back_last_ahoy_event(2)
        end
      end

      @limit = 10
      @most_used_keywords = AhoyQueries.get_most_used_keywords(@limit)
    end

    it "returns an accurate list of the most used keywords in the last 7 days" do
      expect(@most_used_keywords.length).to be <= @limit

      @keywords.each_with_index do |keyword, index|
        count = index+1
        expect(@most_used_keywords[keyword]).to eq(count)
      end
    end

    it "returns a sorted list (descending order) of the most used keywords in the last 7 days" do
      @keywords.each_with_index do |keyword, index|
        if index > 0
          current_keyword_count = @most_used_keywords[keyword]
          previous_keyword_count = @most_used_keywords[@keywords[index-1]]
          expect(current_keyword_count).to be >= previous_keyword_count
        end
      end
    end
  end

  describe "#get_most_visited_locations" do
    before do
      ahoy = Ahoy::Tracker.new
      @first_location = create(:location)
      @second_location = create(:nearby_loc)
      @third_location = create(:farmers_market_loc)

      @location_list = [@first_location, @second_location, @third_location]
      @location_list.each_with_index do |location, n_visits|
        for i in 0..(n_visits) do
          ahoy.track("Location Visit", id: location.id)
          move_date_back_last_ahoy_event(2)
        end
      end

      @limit = 5
      @most_visited_locations = AhoyQueries.get_most_visited_locations(@limit)
    end

    it "returns an accurate list of the most visited locations in the last 7 days" do
      expect(@most_visited_locations.length).to be <= @limit
      expect(@most_visited_locations[@first_location.id]).to eq(1)
      expect(@most_visited_locations[@second_location.id]).to eq(2)
      expect(@most_visited_locations[@third_location.id]).to eq(3)
    end

    it "returns a sorted list (descending order) of the most visited locations in the last 7 days" do
      @location_list.each_with_index do |location, index|
        if index > 0
          current_location_count = @most_visited_locations[location.id]
          previous_location_count = @most_visited_locations[@location_list[index-1].id]
          expect(current_location_count).to be >= previous_location_count
        end
      end
    end
  end

  describe "#determine_origin_of_location_visit and #get_keywords_from_search_events" do
    before do
      ahoy = Ahoy::Tracker.new

      @location = create(:location)
      # visit from direct link
      ahoy.track("Location Visit", id: @location.id)
      move_date_back_last_ahoy_event(2)

      # visit from keyword searches
      @keyword_searches = ["dental care", "health", "clinic"]
      @keyword_searches.each_with_index do |keyword, n_times|
        for i in 0..n_times do
          # track search event
          ahoy.track("Perform Search", keywords: keyword)
          move_date_back_last_ahoy_event(2)

          # track location visit
          ahoy.track("Location Visit", id: @location.id)
          move_date_back_last_ahoy_event(2)
        end
      end

      @visits_origin = AhoyQueries.determine_origin_of_location_visit(@location.id)
    end

    it "returns an accurate list of the origin of location visits in the last 7 days" do
      expect(@visits_origin.length).to eq(7)
    end

    it "returns a list that includes visits from direct links in the last 7 days" do
      expect(@visits_origin.count(nil)).to eq(1)
    end

    it "returns the keywords in the searches that led to the location visits  in the last 7 days" do
      retrieved_search_keywords = AhoyQueries.get_keywords_from_search_events(@visits_origin)

      expect(retrieved_search_keywords.length).to eq(6)

      @keyword_searches.each_with_index do |keyword, index|
        count = index+1
        expect(retrieved_search_keywords.count(keyword)).to eq(count)
      end
    end
  end

  # auxiliar function
  def move_date_back_last_ahoy_event(n_days)
    ahoy_entry = Ahoy::Event.last
    ahoy_entry.update(time: n_days.days.ago)
    ahoy_entry.reload
  end
end

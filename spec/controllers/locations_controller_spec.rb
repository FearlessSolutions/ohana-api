require 'rails_helper'

describe LocationsController do
  # create location with service under the 'Health' category
  before do
    @nearby = create(:nearby_loc)

    health = create(:health)

    @nearby.services.create!(attributes_for(:service))
    service = @nearby.services.first
    service.category_ids = [health.id]
    service.save
  end

  describe "GET 'index'" do
    xit 'returns 200 status code' do
      VCR.use_cassette('all_results') do
        get :index
        expect(response.code).to eq('200')
      end
    end
  end

  describe "track single location visits with ahoy" do
    it 'tracks the visited location id' do
      get :show, params: {id: "#{@nearby.slug}"}

      ahoy_tracked = Ahoy::Event.where(name: 'Location Visit', properties: {id: @nearby.id}).count

      expect(ahoy_tracked).to eq(1)
    end
  end

  describe "track multiple location visits with ahoy" do
    it 'tracks multiple location visits in the same ahoy visit id' do
      get :show, params: {id: "#{@nearby.slug}"}
      @new_test_location = create(:farmers_market_loc)
      get :show, params: {id: "#{@new_test_location.slug}"}

      ahoy_events = Ahoy::Event.where(name: 'Location Visit')
      nearby_loc_tracked = Ahoy::Event.where(name: 'Location Visit', properties: {id: @nearby.id})
      new_loc_tracked = Ahoy::Event.where(name: 'Location Visit', properties: {id: @new_test_location.id})

      expect(ahoy_events.count).to eq(2)
      expect(ahoy_events.first.properties["id"]).to eq(@nearby.id)
      expect(nearby_loc_tracked.count).to eq(1)
      expect(new_loc_tracked.count).to eq(1)
      expect(ahoy_events.first.visit_id).to eq(ahoy_events.last.visit_id)
    end
  end
end

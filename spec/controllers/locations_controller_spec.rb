require 'rails_helper'

describe LocationsController do
  # create location with service under the 'Health' category
  before do
    @nearby = create(:nearby_loc)
    @new_test_location = create(:farmers_market_loc)

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

  describe "track location visits with ahoy" do
    it 'tracks the visited location id' do
      get :show, params: {id: "#{@nearby.slug}"}

      ahoy_tracked = Ahoy::Event.where(name: 'Location Visit', id: @nearby.id).count

      expect(ahoy_tracked).to eq(1)
    end

    it 'tracks multiple location visits in the same ahoy visit id' do
      get :show, params: {id: "#{@nearby.slug}"}
      get :show, params: {id: "#{@new_test_location.slug}"}

      ahoy_tracked = Ahoy::Event.where(name: 'Location Visit')
      nearby_loc_tracked = Ahoy::Event.where(name: 'Location Visit', id: @nearby.id)
      new_loc_tracked = Ahoy::Event.where(name: 'Location Visit', id: @new_test_location.id)

      expect(ahoy_tracked.count).to eq(2)
      expect(nearby_loc_tracked.count).to eq(1)
      expect(new_loc_tracked.count).to eq(1)
      expect(nearby_loc_tracked.last.visit_id).to eq(new_loc_tracked.last.visit_id)
    end
  end
end

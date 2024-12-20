require 'rails_helper'

describe LocationsController do
  #  create location with service under the 'Health' category
  before do
    nearby = create(:nearby_loc)

    health = create(:health)

    nearby.services.create!(attributes_for(:service))
    service = nearby.services.first
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

  describe 'location search tracking' do
    it 'tracks any search' do
      get :index

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').count

      expect(ahoy_tracked).to eq(1)
    end

    it 'tracks a search with params' do
      get :index, params: {keyword: 'house', main_category: '', categories: []}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').count

      expect(ahoy_tracked).to eq(1)
    end

    it 'tracks the search keywords used' do
      get :index, params: {keyword: 'house', main_category: '', categories: []}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').last

      expect(ahoy_tracked.properties['keywords']).to eq('house')
      expect(ahoy_tracked.properties['main_category']).to eq('')
      expect(ahoy_tracked.properties['subcategories']).to eq([])
    end

    it 'tracks the categories and subcategories used' do
      get :index, params: {keyword: '', main_category: 'Health', categories: ['Dental Care', 'General Population']}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').last

      expect(ahoy_tracked.properties['keywords']).to eq('')
      expect(ahoy_tracked.properties['main_category']).to eq('Health')
      expect(ahoy_tracked.properties['subcategories']).to eq(['Dental Care', 'General Population'])
    end

    it 'tracks the number of search results listed' do
      get :index, params: {keyword: 'house', main_category: 'Health', categories: ['Dental Care', 'General Population']}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').last

      expect(ahoy_tracked.properties['results']).to eq(0)
    end

    it 'tracks multiple searches with the same visit id' do
      get :index, params: {keyword: 'house', main_category: '', categories: []}
      get :index, params: {keyword: 'diapers', main_category: '', categories: []}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').all

      expect(ahoy_tracked.count).to eq(2)
      expect(ahoy_tracked.first.visit_id).to eq(ahoy_tracked.last.visit_id)
    end
  end
end

require 'rails_helper'

describe LocationsController do
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
      get :index, params: {keyword: 'house'}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').count

      expect(ahoy_tracked).to eq(1)
    end

    it 'tracks the search keywords used' do
      get :index, params: {keyword: 'house', main_category: ''}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').last

      expect(ahoy_tracked.properties['keywords']).to eq('house')
      expect(ahoy_tracked.properties['main_category']).to eq(nil)
    end

    it 'tracks the number of search results listed' do
      get :index, params: {keyword: 'house', main_category: ''}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').last

      expect(ahoy_tracked.properties['results']).to eq(0)
    end

    it 'tracks multiple searches within the same visit' do
      get :index, params: {keyword: 'house'}
      get :index, params: {keyword: 'diapers'}

      ahoy_tracked = Ahoy::Event.where(name: 'Perform Search').all

      expect(ahoy_tracked.count).to eq(2)
      expect(ahoy_tracked.first.visit_id).to eq(ahoy_tracked.last.visit_id)
    end
  end
end

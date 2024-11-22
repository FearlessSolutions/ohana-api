require 'rails_helper'

describe "GET 'search'" do
  context 'with valid keyword only' do
    before do
      @loc = create(:location)
      @nearby = create(:nearby_loc)
      @loc.update_columns(updated_at: Time.zone.now - 1.day)
      @nearby.update_columns(updated_at: Time.zone.now - 1.hour)
      LocationsIndex.reset!

      get api_search_index_url(keyword: 'jobs', per_page: 1)
    end

    it 'returns a successful status code' do
      expect(response).to be_successful
    end

    it 'is json' do
      expect(response.content_type).to eq('application/json; charset=utf-8')
    end

    it 'returns locations' do
      expect(json.first.keys).to include('coordinates')
    end

    it 'is a paginated resource' do
      get api_search_index_url(
        keyword: 'jobs', per_page: 1, page: 2
      )
      expect(json.length).to eq(1)
    end

    it 'returns an X-Total-Count header' do
      expect(response.status).to eq(200)
      expect(json.length).to eq(1)
      expect(headers['X-Total-Count']).to eq '2'
    end

    it 'sorts by updated_at when results have same full text search rank', broken: true do
      expect(json.first['name']).to eq @nearby.name
    end
  end

  describe 'specs that depend on :farmers_market_loc factory', broken: true do
    # We need to handle our new search logic based on location, coordinates, and radius.
    # Currently marking these specs as broken.

    before do
      create(:farmers_market_loc)
      LocationsIndex.reset!
    end

    context 'with radius too small but within range' do
      it 'returns the farmers market name' do
        get api_search_index_url(
          location: 'la honda, ca', radius: 0.05
        )
        expect(json.first['name']).to eq('Belmont Farmers Market')
      end
    end

    context 'with radius too big but within range' do
      it 'returns the farmers market name' do
        get api_search_index_url(
          location: 'san gregorio, ca', radius: 50
        )
        expect(json.first['name']).to eq('Belmont Farmers Market')
      end
    end

    context 'with radius not within range' do
      it 'returns an empty response array' do
        get api_search_index_url(
          location: 'pescadero, ca', radius: 5
        )
        expect(json).to eq([])
      end
    end

    context 'with invalid zip' do
      it 'returns no results' do
        get api_search_index_url(location: '00000')
        expect(json.length).to eq 0
      end
    end

    context 'with invalid location' do
      it 'returns no results' do
        get api_search_index_url(location: '94403ab')
        expect(json.length).to eq 0
      end
    end
  end

  describe 'specs that depend on :location factory', broken: true do
    before do
      create(:location)
    end

    context 'with invalid radius' do
      before do
        get api_search_index_url(location: '94403', radius: 'ads')
      end

      it 'returns a 400 status code' do
        expect(response.status).to eq(400)
      end

      it 'is json' do
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end

      it 'includes an error description' do
        expect(json['description']).to eq('Radius must be a Float between 0.1 and 50.')
      end
    end

    context 'with invalid lat_lng parameter' do
      before do
        get api_search_index_url(lat_lng: '37.6856578-122.4138119')
      end

      it 'returns a 400 status code' do
        expect(response.status).to eq 400
      end

      it 'includes an error description' do
        expect(json['description']).
          to eq 'lat_lng must be a comma-delimited lat,long pair of floats.'
      end
    end

    context 'with invalid (non-numeric) lat_lng parameter' do
      before do
        get api_search_index_url(lat_lng: 'Apple,Pear')
      end

      it 'returns a 400 status code' do
        expect(response.status).to eq 400
      end

      it 'includes an error description' do
        expect(json['description']).
          to eq 'lat_lng must be a comma-delimited lat,long pair of floats.'
      end
    end

    context 'with plural version of keyword' do
      it "finds the plural occurrence in location's name field" do
        get api_search_index_url(keyword: 'services')
        expect(json.first['name']).to eq('VRS Services')
      end

      it "finds the plural occurrence in location's description field" do
        get api_search_index_url(keyword: 'jobs')
        expect(json.first['description']).to eq('Provides jobs training')
      end
    end

    context 'with singular version of keyword' do
      it "finds the plural occurrence in location's name field" do
        get api_search_index_url(keyword: 'service')
        expect(json.first['name']).to eq('VRS Services')
      end

      it "finds the plural occurrence in location's description field" do
        get api_search_index_url(keyword: 'job')
        expect(json.first['description']).to eq('Provides jobs training')
      end
    end
  end

  describe 'specs that depend on :location and :nearby_loc' do
    before do
      create(:location)
      create(:nearby_loc)
      LocationsIndex.reset!
    end

    context 'when keyword only matches one location' do
      it 'only returns 1 result' do
        get api_search_index_url(keyword: 'library')
        expect(json.length).to eq(1)
      end
    end

    context "when keyword doesn't match anything" do
      it 'returns no results' do
        get api_search_index_url(keyword: 'blahab')
        expect(json.length).to eq(0)
      end
    end

    context 'with keyword and location parameters', broken: true do
      # TODO: Need to handle location search in new search logic.
      # Currently we consider postal_code search for location.
      it 'only returns locations matching both parameters' do
        get api_search_index_url(
          keyword: 'books', location: 'Burlingame'
        )
        expect(headers['X-Total-Count']).to eq '1'
        expect(json.first['name']).to eq('Library')
      end
    end

    context 'when keyword parameter has multiple words', broken: true do
      it 'only returns locations matching all words' do
        get api_search_index_url(keyword: 'library books jobs')
        expect(headers['X-Total-Count']).to eq '1'
        expect(json.first['name']).to eq('Library')
      end
    end
  end

  context 'lat_lng search', broken: true do
    it 'returns one result' do
      create(:location)
      create(:farmers_market_loc)
      get api_search_index_url(lat_lng: '37.583939,-122.3715745')
      expect(json.length).to eq 1
    end
  end

  context 'with singular version of keyword', broken: true do
    it 'finds the plural occurrence in organization name field' do
      # TODO: Need to handle singulr word search for keyword.
      create(:nearby_loc)
      get api_search_index_url(keyword: 'food stamp')
      expect(json.first['organization']['name']).to eq('Food Stamps')
    end

    it "finds the plural occurrence in service's keywords field", broken: true do
      # TODO: Need to handle singulr word search for keyword.
      create_service
      get api_search_index_url(keyword: 'pantry')
      expect(json.first['name']).to eq('VRS Services')
    end
  end

  context 'with plural version of keyword' do
    it 'finds the plural occurrence in organization name field', broken: true do
      # TODO: Need to handle plural word search for keyword.
      create(:nearby_loc)
      get api_search_index_url(keyword: 'food stamps')
      expect(json.first['organization']['name']).to eq('Food Stamps')
    end

    it "finds the plural occurrence in service's keywords field", broken: true do
      # TODO: Need to handle plural word search for keyword.
      create_service
      get api_search_index_url(keyword: 'emergencies')
      expect(json.first['name']).to eq('VRS Services')
    end
  end

  context 'when keyword matches category name' do
    before do
      create(:far_loc)
      create(:loc_with_nil_fields)
      cat = create(:category)
      create_service
      @service.category_ids = [cat.id]
      @service.save!
    end

    it 'boosts location whose services category name matches the query', broken: true do
      # TODO: Need to handle boost for service category name in new search logic
      get api_search_index_url(keyword: 'food')
      expect(headers['X-Total-Count']).to eq '3'
      expect(json.first['name']).to eq 'VRS Services'
    end
  end

  context 'with org_name parameter' do
    before do
      create(:nearby_loc)
      create(:location)
      create(:soup_kitchen)
      LocationsIndex.reset!
    end

    it 'returns results when org_name only contains one word that matches' do
      get api_search_index_url(org_name: 'stamps')
      expect(headers['X-Total-Count']).to eq '1'
      expect(json.first['name']).to eq('Library')
    end

    it 'only returns locations whose org name matches all terms' do
      get api_search_index_url(org_name: 'Food+Pantry')
      expect(headers['X-Total-Count']).to eq '1'
      expect(json.first['name']).to eq('Soup Kitchen')
    end

    it 'allows searching for both org_name and location', broken: true do
      # TODO: Need to handle location search in new search logic.
      # Currently we consider postal_code search for location.
      get api_search_index_url(
        org_name: 'stamps',
        location: '1236 Broadway, Burlingame, CA 94010'
      )
      expect(headers['X-Total-Count']).to eq '1'
      expect(json.first['name']).to eq('Library')
    end

    it 'allows searching for blank org_name and location', broken: true do
      # TODO: Need to handle serach logic for empty org_name. Current search logic
      # does not support this.
      get api_search_index_url(org_name: '', location: '')
      expect(response.status).to eq 200
      expect(json.length).to eq(3)
    end
  end

  context 'when email parameter contains custom domain', broken: true do
    # TODO: Need to handle pagination and email logic in search logic.

    it "finds domain name when url contains 'www'" do
      create(:location, website: 'http://www.smchsa.org')
      create(:nearby_loc, email: 'info@cfa.org')
      get "#{api_search_index_url}?email=foo@smchsa.org"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'finds naked domain name' do
      create(:location, website: 'http://smchsa.com')
      create(:nearby_loc, email: 'hello@cfa.com')
      get "#{api_search_index_url}?email=foo@smchsa.com"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'finds long domain name in both url and email' do
      create(:location, website: 'http://smchsa.org')
      create(:nearby_loc, email: 'info@smchsa.org')
      get "#{api_search_index_url}?email=foo@smchsa.org"
      expect(headers['X-Total-Count']).to eq '2'
    end

    it 'finds domain name when URL contains path' do
      create(:location, website: 'http://www.smchealth.org/mcah')
      create(:nearby_loc, email: 'org@mcah.org')
      get "#{api_search_index_url}?email=foo@smchealth.org"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'finds domain name when URL contains multiple paths' do
      create(:location, website: 'http://www.smchsa.org/portal/site/planning')
      create(:nearby_loc, email: 'sanmateo@ca.us')
      get "#{api_search_index_url}?email=foo@smchsa.org"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'finds domain name when URL contains a dash' do
      create(:location, website: 'http://www.bar-connect.ca.gov')
      create(:nearby_loc, email: 'gov@childsup-connect.gov')
      get "#{api_search_index_url}?email=foo@bar-connect.ca.gov"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'finds domain name when URL contains a number' do
      create(:location, website: 'http://www.prenatalto3.org')
      create(:nearby_loc, email: 'info@rwc2020.org')
      get "#{api_search_index_url}?email=foo@prenatalto3.org"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'returns locations where either email or admins fields match' do
      create(:location, email: 'moncef@smcgov.org')
      create(:location_with_admin)
      get api_search_index_url(email: 'moncef@smcgov.org')
      expect(headers['X-Total-Count']).to eq '2'
    end

    it 'does not return locations if email prefix is the only match' do
      create(:location, email: 'moncef@smcgov.org')
      create(:location_with_admin)
      get api_search_index_url(email: 'moncef@gmail.com')
      expect(headers['X-Total-Count']).to eq '0'
    end
  end

  context 'when email parameter contains generic domain', broken: true do
    # TODO: Need to handle search using email entity.

    it "doesn't return results for gmail domain" do
      create(:location, email: 'info@gmail.com')
      get "#{api_search_index_url}?email=foo@gmail.com"
      expect(headers['X-Total-Count']).to eq '0'
    end

    it "doesn't return results for aol domain" do
      create(:location, email: 'info@aol.com')
      get "#{api_search_index_url}?email=foo@aol.com"
      expect(headers['X-Total-Count']).to eq '0'
    end

    it "doesn't return results for hotmail domain" do
      create(:location, email: 'info@hotmail.com')
      get "#{api_search_index_url}?email=foo@hotmail.com"
      expect(headers['X-Total-Count']).to eq '0'
    end

    it "doesn't return results for yahoo domain" do
      create(:location, email: 'info@yahoo.com')
      get "#{api_search_index_url}?email=foo@yahoo.com"
      expect(headers['X-Total-Count']).to eq '0'
    end

    it "doesn't return results for sbcglobal domain" do
      create(:location, email: 'info@sbcglobal.net')
      get "#{api_search_index_url}?email=foo@sbcglobal.net"
      expect(headers['X-Total-Count']).to eq '0'
    end

    it 'does not return locations if domain is the only match' do
      create(:location, email: 'moncef@gmail.com', admin_emails: ['moncef@gmail.com'])
      get api_search_index_url(email: 'foo@gmail.com')
      expect(headers['X-Total-Count']).to eq '0'
    end

    it 'returns results if admin email matches parameter' do
      create(:location, admin_emails: ['info@sbcglobal.net'])
      get "#{api_search_index_url}?email=info@sbcglobal.net"
      expect(headers['X-Total-Count']).to eq '1'
    end

    it 'returns results if email matches parameter' do
      create(:location, email: 'info@sbcglobal.net')
      get "#{api_search_index_url}?email=info@sbcglobal.net"
      expect(headers['X-Total-Count']).to eq '1'
    end
  end

  context 'when email parameter only contains generic domain name' do
    it "doesn't return results", broken: true do
      # TODO: Need to update email search logic.
      create(:location, email: 'info@gmail.com')
      get api_search_index_url(email: 'gmail.com')
      expect(headers['X-Total-Count']).to eq '0'
    end
  end

  describe 'sorting search results' do
    context 'sort when only location is present' do
      it 'sorts by distance by default', broken: true do
        # TODO: Need to update location search logic.
        create(:location)
        create(:nearby_loc)
        get api_search_index_url(
          location: '1236 Broadway, Burlingame, CA 94010'
        )
        expect(json.first['name']).to eq('VRS Services')
      end
    end
  end

  context 'when location has missing fields' do
    it 'includes attributes with nil or empty values' do
      create(:loc_with_nil_fields)
      LocationsIndex.reset!
      get api_search_index_url(keyword: 'belmont')
      keys = json.first.keys
      %w[phones address].each do |key|
        expect(keys).to include(key)
      end
    end
  end

  context 'with misspelled query' do
    before do
      @loc1 = create(:location)
    end

    it "should return correct location if query is 'covis-19'" do
      @loc1.update!(name: 'covid-19 word location')
      LocationsIndex.reset!

      get api_search_index_url(keyword: 'covis-19')
      expect(json.first['name']).to eq('covid-19 word location')
    end

    it "should return correct location if query is 'acheive'" do
      @loc1.update_columns(description: 'achieve word in description', slug: 'www.example.com')
      LocationsIndex.reset!

      get api_search_index_url(keyword: 'acheive')
      expect(json.first['description']).to eq('achieve word in description')
    end

    it "should return correct location if query is 'seperate'" do
      organization = @loc1.organization
      organization.update!(name: 'separate word in organization')
      LocationsIndex.reset!

      get api_search_index_url(keyword: 'seperate')
      expect(json.first['organization']['name']).to eq('separate word in organization')
    end
  end

  context 'it should order the locations' do
    before do
      @organization = create(:organization)

      @loc1 = create_location("Not featured", @organization)
      @loc2 = create_location("featured location", @organization, "1")

      LocationsIndex.reset!
    end

    it 'it should return featured locations first, and then the rest' do
      LocationsIndex.reset!

      get api_search_index_url(keyword: 'parent')

      sleep 0.5

      expect(json[0]['name']).to eq(@loc2.name)
      expect(json[1]['name']).to eq(@loc1.name)
    end

    it 'it should return locations order based on updated_at property if no featured_at' do
      time = Time.current

      @loc1.update_columns(name: "regular location2", updated_at: time - 3.minutes)
      @loc2.update_columns(name: "regular location3", featured_at: time, updated_at: time - 1.minutes)

      LocationsIndex.reset!

      get api_search_index_url(keyword: 'parent')

      sleep 0.5

      expect(json[0]['name']).to eq(@loc2.name)
      expect(json[1]['name']).to eq(@loc1.name)
    end
  end
end

private

def create_location(name, organization, featured = "0")
  create(:location, name: name, organization: organization, featured: featured)
end

def search(attributes = {})
  described_class.new(attributes).search.load
end


def import(*args)
  ServicesIndex.import!(*args)
end

require 'rails_helper'
require 'pry'
RSpec.describe LocationsSearch, :elasticsearch do
  def search(attributes = {})
    described_class.new(attributes).search.load
  end

  def import(*args)
    LocationsIndex.import!(*args)
  end

  describe 'Search Overall Results order' do
    specify 'the results should follow the following order 1. Featured  2. Exact Matches 3. Partial Matches 4. tagged Results' do
      org = create(:organization, name: 'Regular Name')
      LocationsIndex.reset!

      featured_location = create_location("Featured - Salvation Church", org, "1")
      location_name_exact_match = create_location("Salvation Army", org)
      location_name_partial_match = create_location("Salvation Army from Baltimore Maryland", org)

      tag_1 = create(:tag, name: "Salvation")
      tag_2 = create(:tag, name: "Army")

      organization_with_matching_tags = create(:organization, name: 'Definitely doesnt contain terms')
      organization_with_matching_tags.tags << tag_1
      organization_with_matching_tags.tags << tag_2

      location_with_org_matching_tags = create_location("Location with associated Tagged Organization", organization_with_matching_tags)

      location_random_attributes = create_location("Random Location", org)

      import(featured_location, location_name_exact_match, location_name_partial_match, location_with_org_matching_tags)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results[0].id).to eq(location_name_exact_match.id)
      expect(results[1].id).to eq(location_name_partial_match.id)
      expect(results[2].id).to eq(featured_location.id)
      expect(results[3].id).to eq(location_with_org_matching_tags.id)
      expect(results).not_to include(location_random_attributes)
    end
  end

  describe 'Exact Matches should be ordered like this: (after featured) 1.Organization Name 2.Location Name 3.Service Category 4.Service Subcategory' do
    specify 'Organization name exact match should be on top of service category exact match' do

      org_exact_match = create(:organization, name: 'Financial Aid And Loans')
      org_regular_name = create(:organization, name: 'Regular Name not containing any relevant terms')
      LocationsIndex.reset!

      featured_location = create_location("financial aid and nice loans", org_regular_name, "1")
      location_organization_match = create_location("Financial Aid And Happy Loans", org_exact_match)
      location_category_service_match = create_location("Location with Service category exact match", org_regular_name)

      service_exact_match = create(:service, location: location_category_service_match, name: "Service category exact match")
      category_exact_match = create(:category, services: [service_exact_match], name: "Financial Aid And Loans")

      time = Time.current

      # Set for all of them the same updated_at time stamp so they get ordered only considering score
      featured_location.update_columns(updated_at: time)
      location_organization_match.update_columns(updated_at: time)
      location_category_service_match.update_columns(updated_at: time)

      import(featured_location, location_organization_match, location_category_service_match)

      results = search({keywords: 'Financial Aid And Loans'}).objects

      expect(results[0].id).to be(location_organization_match.id)
      expect(results[1].id).to be(featured_location.id)
      expect(results[2].id).to be(location_category_service_match.id)
    end

    specify 'Location Name exact match should be on top of service sub category exact match' do

      org_regular_name = create(:organization, name: 'Regular Name not containing any relevant terms')
      LocationsIndex.reset!

      featured_location = create_location("financial aid and nice loans", org_regular_name, "1")
      location_name_exact_match = create_location("Financial Aid And Loans", org_regular_name)

      org_sub_cat = create(:organization, name: 'Sub Cat Org')
      location_sub_category_service_match = create_location("Location with Service sub category exact match", org_sub_cat)
      service_sub_cat = create(:service, location: location_sub_category_service_match, name: "Service sub category exact match")
      sub_cat = create(:financial_aid, services: [service_sub_cat])

      time = Time.current

      # Set for all of them the same updated_at time stamp so they get ordered only considering score
      featured_location.update_columns(updated_at: time)
      location_name_exact_match.update_columns(updated_at: time)
      location_sub_category_service_match.update_columns(updated_at: time)

      import(featured_location, location_name_exact_match, location_sub_category_service_match)

      results = search({keywords: 'Financial Aid And Loans'}).objects

      expect(results[0].id).to be(location_name_exact_match.id)
      expect(results[1].id).to be(featured_location.id)
      expect(results[2].id).to be(location_sub_category_service_match.id)
    end
  end

  xdescribe 'by organization name', debt: true do
    specify 'partial match on org name tops partial match on location name or service name' do

      org1 = create(:organization, name: 'Partial Match on Org Name DRUG COMPANY')
      org2 = create(:organization, name: 'Not At All a Match Group')
      LocationsIndex.reset!

      location_1 = create_location("org name partial match", org1)
      location_2 = create_location("location name partial match DRUG COMPANY", org2)
      location_3 = create_location("Service name partial match", org2)

      service = create(:service, location: location_3, name: "Service with matching terms on category name")
      create(:category, services: [service], name: "Catgory for DRUG COMPANY supplies")

      time = Time.current

      # Set for all of them the same updated_at time stamp so they get ordered only considering score
      location_1.update_columns(updated_at: time)
      location_2.update_columns(updated_at: time)
      location_3.update_columns(updated_at: time)

      import(location_1, location_2, location_3)

      results = search({keywords: 'DRUG COMPANY'}).objects

      expect(results[0].id).to be(location_1.id)
      expect(results[1].id).to be(location_2.id)
      expect(results[2].id).to be(location_3.id)
    end
  end

  describe 'by location name' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'exact matches on location names are included in results' do
      location_1 = create_location("NOT EVEN CLOSE", @organization)
      location_2 = create_location("EXACT MATCH OF NAME", @organization)

      import(location_1, location_2)

      results = search({keywords: 'EXACT MATCH OF NAME'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end

    specify 'exact matches are prioritized over partial matches' do
      location_1 = create_location("DEAD ON EXACT MATCH BUDDY", @organization)
      location_2 = create_location("PARTIAL MATCH ON BUDDY", @organization)

      import(location_1, location_2)

      results = search({keywords: 'DEAD ON EXACT MATCH BUDDY'})

      expect(results[0].id).to be(location_1.id)
      expect(results[1].id).to be(location_2.id)
    end
  end

  describe 'by location description' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'location description contains "Salvation" OR "Army"' do
      location_1 = create_location("NOT EVEN CLOSE", @organization)
      location_2 = create_location("DESCRIPTION CONTAINS THE FIRST TERM", @organization)
      location_3 = create_location("DESCRIPTION CONTAINS THE SECOND TERM", @organization)

      location_1.update_columns(description: "This is a description that has no relationship or reference to the terms in the search query.")
      location_2.update_columns(description: "This is a description that contains the word Salvation. So it should show up in the results.")
      location_3.update_columns(description: "This is a description that contains the word Army. So it should show up in the results.")

      import(location_1, location_2, location_3)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_3)
      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end

    specify 'location description contains "Salvation" AND "Army"' do
      location_1 = create_location("NOT EVEN CLOSE", @organization)
      location_2 = create_location("EXACT MATCH OF NAME", @organization)

      location_1.update_columns(description: "This is a description that has no relationship or reference to the terms in the search query.")
      location_2.update_columns(description: "This is a description that contains the word Salvation AND also it contains the world Army. So it should show up in the results.")

      import(location_1, location_2)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end
  end

  describe 'terms matching across two fields' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'location description contains "Salvation" AND service description contains "Army"' do
      location_1 = create_location("NOT EVEN CLOSE", @organization)
      location_2 = create_location("EXACT MATCH IN TWO FIELDS", @organization)

      location_1.update_columns(description: "This is a description that has no relationship or reference to the terms in the search query.")
      location_2.update_columns(description: "This is a description that contains the word Salvation")
      service = create(:service, location: location_2, description: "This one has the word Army in it.")

      import(location_1, location_2)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end
  end

  describe 'by service name' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'matches on location that has service name with TERM1 OR TERM2' do
      location_1 = create_location("service name don't match", @organization)
      location_2 = create_location("Has service with the first term", @organization)
      location_3 = create_location("Has service with the second term", @organization)

      service_1 = create(:service, location: location_1, name: "Service name with neither term")
      service_2 = create(:service, location: location_2, name: "Salvation but not the second")
      service_3 = create(:service, location: location_3, name: "Army but not the first")

      import(location_1, location_2, location_3)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_3)
      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end

    specify 'matches on location that has service name with TERM1 AND TERM2' do
      location_1 = create_location("service name don't match", @organization)
      location_2 = create_location("Has service with both terms", @organization)

      service_1 = create(:service, location: location_1, name: "Service name with neither term")
      service_2 = create(:service, location: location_2, name: "Salvation but also Army")

      import(location_1, location_2)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end
  end

  describe 'by service description' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'matches on location that has service description with TERM1 OR TERM2' do
      location_1 = create_location("service description don't match", @organization)
      location_2 = create_location("Has service description with first term", @organization)
      location_3 = create_location("Has service description with second term", @organization)

      service_1 = create(:service, location: location_1, description: "Service name with neither term")
      service_2 = create(:service, location: location_2, description: "Salvation but not 2")
      service_3 = create(:service, location: location_3, description: "Army but not 1")

      import(location_1, location_2, location_3)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_3)
      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end

    specify 'matches on location that has service description with TERM1 AND TERM2' do
      location_1 = create_location("service description don't match", @organization)
      location_2 = create_location("Has service description with both terms", @organization)

      service_1 = create(:service, location: location_1, description: "Service name with neither term")
      service_2 = create(:service, location: location_2, description: "Has the words Salvation and the word Army")

      import(location_1, location_2)

      results = search({keywords: 'Salvation Army'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end
  end

  describe 'by service category' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'exact matches on service categories are included in results' do
      location_1 = create_location("service categories don't match", @organization)
      location_2 = create_location("service categories contain a partial match", @organization)

      service_1 = create(:service, location: location_1)
      service_2 = create(:service, location: location_2)

      create(:category, services: [service_2], name: "QWERTY UIOP")

      import(location_1, location_2)

      results = search({keywords: 'QWERTY UIOP'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end

    specify 'partial matches on service categories are included in results' do
      location_1 = create_location("service categories don't match", @organization)
      location_2 = create_location("service categories contain a partial match", @organization)

      service_1 = create(:service, location: location_1)
      service_2 = create(:service, location: location_2)

      create(:category, services: [service_2], name: "QWERTY UIOP")

      import(location_1, location_2)

      results = search({keywords: 'QWERTY'}).objects

      expect(results).to include(location_2)
      expect(results).not_to include(location_1)
    end
  end

  describe 'featured locations' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'featured locations to the top' do
      location_1 = create_location("control", @organization)
      location_2 = create_location("not featured", @organization)
      location_3 = create_location("featured location", @organization, "1")

      import(location_1, location_2, location_3)

      results = search().objects

      expect(results.first.id).to be(location_3.id)
    end
  end

  describe 'archive location search' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    specify 'only returns locations not archived' do
      location_1 = create_location("covid location", @organization)
      location_2 = create_location("Not featured and not covid", @organization)
      location_3 = create_location("featured location", @organization, "1")


      location_1.update_columns(archived_at: Time.zone.yesterday)
      location_2.update_columns(archived_at: nil)
      location_3.update_columns(archived_at: Time.zone.yesterday)

      import(location_1, location_2, location_3)

      results = search().objects
      expect(results).to contain_exactly(location_2)
      expect(results.size).to eq(1)
      expect(results).not_to include([location_1, location_3])

      location_1.update_columns(archived_at: nil)
      location_2.update_columns(archived_at: Time.zone.yesterday)
      location_3.update_columns(archived_at: nil)

      import(location_1, location_2, location_3)

      results = search().objects
      expect(results).to include(location_1, location_3)
      expect(results.size).to eq(2)
      expect(results).not_to include(location_2)
    end
  end

  describe 'archive location search' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    it 'should return only filtered by accessibility options' do
      location_1 = create_location("covid location", @organization)
      location_2 = create_location("Not featured and not covid", @organization)
      location_3 = create_location("featured location", @organization, "1")

      location_1.update_columns(accessibility: ['ramp'])
      location_2.update_columns(accessibility: ['tape_braille', 'disabled_parking'])
      location_3.update_columns(accessibility: ['tape_braille', 'disabled_parking'])

      import(location_1, location_2, location_3)

      results = search({accessibility: ['ramp']}).objects
      expect(results).to include(location_1)
      expect(results.size).to eq(1)
      expect(results).not_to include(location_2, location_3)

      location_1.update_columns(accessibility: ['disabled_parking'])
      location_2.update_columns(accessibility: ['ramp'])
      location_3.update_columns(accessibility: ['ramp'])

      import(location_1, location_2, location_3)

      results = search({accessibility: ['disabled_parking']}).objects

      expect(results).to include(location_1)
      expect(results.size).to eq(1)
      expect(results).not_to include(location_2, location_3)
    end
  end

  describe 'location search' do
    before do
      @organization = create(:organization)
      LocationsIndex.reset!
    end

    it 'should return same results searching with and without stoping words' do
      location_1 = create_location("Animal Shelter", @organization)
      location_2 = create_location("Food and Shelter", @organization)
      location_3 = create_location("This is a Featured location", @organization)

      import(location_1, location_2, location_3)

      results_no_stop_words = search({keywords: 'Animal Shelter'}).objects
      expect(results_no_stop_words).to include(location_1)
      expect(results_no_stop_words).to include(location_2)
      expect(results_no_stop_words.size).to eq(2)

      results_with_stop_words = search({keywords: 'the Animal Shelter is an a'}).objects
      expect(results_with_stop_words).to include(location_1)
      expect(results_with_stop_words).to include(location_2)
      expect(results_with_stop_words.size).to eq(2)
    end
  end

  describe 'location search matching tags' do
    before do
    end

    it 'partial matches should precede tag matches' do
      organization = create(:organization)
      LocationsIndex.reset!

      location_1 = create(:location_with_tag)
      location_2 = create_location("Education Location Partial Match", organization)
      import(location_1, location_2)

      results = search({keywords: 'Education'}).objects
      expect(results[0].id).to eq(location_2.id)
      expect(results.size).to eq(2)
    end

    it 'sorts results containing both 2 terms' do
      organization = create(:organization)
      LocationsIndex.reset!

      term_1 = "Salvation"
      term_2 = "Army"
      terms = [term_1, term_2]
      keywords = terms.join(" ")

      # Location description containing “Salvation” AND “Army”
      location_desc_and_match = create_location("Match in Description", organization)
      location_desc_and_match.update_columns(description: "This description contains both terms: #{keywords}")

      # Service name containing “Salvation” AND “Army”
      location_service_name_and_match = create_location("Match in Service Name", organization)
      service_name_and_match = create(:service, location: location_service_name_and_match, name: "Service Name containing both terms: #{keywords}")

      # Service description containing “Salvation” AND “Army”
      location_service_dec_and_match = create_location("Match in Service description", organization)
      service_dec_and_match = create(:service, location: location_service_dec_and_match, description: "Service Description containing both terms: #{keywords}")

      # Location with no matching keywords
      location_random_terms = create_location("Random location", organization)

      time = Time.current

      # Set for all of them the same updated_at time stamp so they get ordered only considering score
      location_desc_and_match.update_columns(updated_at: time)
      location_service_name_and_match.update_columns(updated_at: time)
      location_service_dec_and_match.update_columns(updated_at: time)
      location_random_terms.update_columns(updated_at: time)

      import(location_desc_and_match, location_service_name_and_match, location_service_dec_and_match, location_random_terms)

      results = search({keywords: "#{term_1} #{term_2}"}).objects

      # Locations with matches on service-related fields rank higher than matches on location description,
      #  and matches on service name weigh more than matches on service description,
      #  therefore the expected results order is:
      #  1. location_service_name_and_match
      #  2. location_service_dec_and_match
      #  3. location_desc_and_match
      expect(results.first.id).to eq(location_service_name_and_match.id)
      expect(results.second.id).to eq(location_service_dec_and_match.id)
      expect(results.third.id).to eq(location_desc_and_match.id)
      expect(results).not_to include(location_random_terms)
    end

    it 'sorts results containing 1 of 2 terms' do
      organization = create(:organization)
      LocationsIndex.reset!

      term_1 = "Salvation"
      term_2 = "Army"
      terms = [term_1, term_2]
      keywords = terms.join(" ")

      # Location description containing “Salvation” OR “Army”
      location_1 = create_location("Match in Description", organization)
      location_1.update_columns(description: "This description contains one of the two terms: #{terms[rand(0..1)]}")

      # Service name containing “Salvation” OR “Army”
      location_2 = create_location("Match in Service Name", organization)
      service_1 = create(:service, location: location_2, name: "Service Name containing one of the terms: #{terms[rand(0..1)]}")

      # Service description containing “Salvation” OR “Army”
      location_3 = create_location("Match in Service description", organization)
      service_2 = create(:service, location: location_3, description: "Service Description containing one of the terms: #{terms[rand(0..1)]}")

      time = Time.current

      # Set for all of them the same updated_at time stamp so they get ordered only considering score
      location_1.update_columns(updated_at: time)
      location_2.update_columns(updated_at: time)
      location_3.update_columns(updated_at: time)

      import(location_1, location_2, location_3)

      results = search({keywords: "#{term_1} #{term_2}"}).objects

      # Locations with matches on service-related fields rank higher than matches on location description,
      #  and matches on service name weigh more than matches on service description,
      #  therefore the expected results order is:
      #  1. location_2 -> match on service name
      #  2. location_3 -> match on service description
      #  3. location_1 -> match on location description
      expect(results[0].id).to eq(location_2.id)
      expect(results[1].id).to eq(location_3.id)
      expect(results[2].id).to eq(location_1.id)
    end

    it 'sorts tagged results' do
      org = create(:organization)
      LocationsIndex.reset!

      term_1 = "Salvation"
      term_2 = "Army"

      tag_1 = create(:tag, name: term_1)
      tag_2 = create(:tag, name: term_2)

      # creates organization with BOTH tags
      organization = create(:organization, name: 'Definitely doesnt contain terms')
      organization.tags << tag_1
      organization.tags << tag_2

      # 1. Associated org with tags containing “Salvation” tag AND “Army” tag
      location_1 = create_location("Location with tagged Organization ", organization)

      # creates location with FIRST tag
      # 2. Location contains "Salvation" tag AND associated service contains "Army" tag
      location_2 = create_location("Location with one tag", org)
      location_2.tags << tag_1

      # and service on that location with the second tag!
      service_with_second_tag = create(:service, location: location_2)
      service_with_second_tag.tags << tag_2

      # 3. Services with tags containing “Salvation” OR “Army”
      location_3 = create_location("Single matching tag on service", org)
      service_with_matching_tag = create(:service, location: location_3)
      service_with_matching_tag.tags << tag_2

      import(location_1, location_2, location_3)

      results = search({keywords: "#{term_1} #{term_2}"}).objects

      # Service tags weigh more than organization tags and service tags are boosted, unlike location tags,
      #  therefore the expected results order is:
      #  1. location_3 -> service tags weigh more than location tags and are also boosted
      #  2. location_2
      #  3. location_3 -> only organization tags
      expect(results.first.id).to eq(location_3.id)
      expect(results.second.id).to eq(location_2.id)
      expect(results.third.id).to eq(location_1.id)
    end

    it 'should return locations matching the location - tags' do
      organization = create(:organization)
      LocationsIndex.reset!

      # tag name (Education) taken from tags factory
      location_1 = create(:location_with_tag)
      location_2 = create_location("Location with no tag", organization)
      import(location_1, location_2)

      results = search({keywords: 'Education'}).objects
      expect(results).to include(location_1)
      expect(results.size).to eq(1)

    end

    it 'should return locations matching the locations organization - tags' do
      organization = create(:organization)
      LocationsIndex.reset!

      organization_with_tag = create(:organization_with_tag)
      location_1 = create_location("Location with tagged organization", organization_with_tag)
      location_2 = create_location("Location with no tagged organization", organization)
      import(location_1, location_2)

      results = search({keywords: 'Organization_tag'}).objects
      expect(results).to include(location_1)
      expect(results.size).to eq(1)
    end

    it 'should return locations matching the locations services - tags' do
      organization = create(:organization)
      LocationsIndex.reset!

      location_1 = create(:location, organization: organization)
      service = create(:service, location: location_1)
      service.tags << create(:tag_service)
      location_2 = create_location("Location with no tagged services", organization)

      import(location_1, location_2)
      results = search({keywords: 'Service_tag'}).objects
      expect(results).to include(location_1)
      expect(results.size).to eq(1)
    end
  end
end

private

def create_location(name, organization, featured = "0")
  create(:location, name: name, organization: organization, featured: featured)
end

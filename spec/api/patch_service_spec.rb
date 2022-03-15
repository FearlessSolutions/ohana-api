require 'rails_helper'

describe 'PATCH /locations/:location_id/services/:id' do
  before do
    create_service
    @attrs = attributes_for(:service_with_extra_whitespace)
  end

  let(:expected_attributes) do
    {
      accepted_payments: %w[Cash Credit],
      alternate_name: 'AKA',
      audience: 'Low-income seniors',
      description: 'SNAP market',
      address_details: 'Entrance through red door.',
      eligibility: 'seniors',
      email: 'foo@example.com',
      fees: 'none',
      funding_sources: %w[County],
      application_process: 'in person',
      interpretation_services: 'CTS LanguageLink',
      keywords: %w[health yoga],
      languages: %w[French English],
      name: 'Benefits',
      required_documents: %w[ID],
      service_areas: %w[Belmont],
      status: 'active',
      website: 'http://www.monfresh.com',
      wait_time: '2 days'
    }
  end

  let(:array_attributes) do
    %w[accepted_payments funding_sources keywords languages required_documents service_areas]
  end

  it 'returns 200 when validations pass' do
    patch(
      api_location_service_url(@location, @service),
      @attrs
    )

    expect(response).to have_http_status(200)
    expected_attributes.each do |key, value|
      expect(json[key.to_s]).to eq value
    end
  end

  it "updates the location's service" do
    patch(
      api_location_service_url(@location, @service),
      @attrs
    )
    get api_location_url(@location)
    expect(json['services'].first['description']).to eq expected_attributes[:description]
  end

  it "doesn't add a new service" do
    patch(
      api_location_service_url(@location, @service),
      @attrs
    )
    expect(Service.count).to eq(1)
  end

  it 'requires a valid service id' do
    patch(
      api_location_service_url(@location, 123),
      @attrs
    )
    expect(response.status).to eq(404)
    expect(json['message']).
      to eq('The requested resource could not be found.')
  end

  # BAHC relaxed the validation on service areas to allow import of iCarol data
  xit 'returns 422 when attribute is invalid' do
    patch(
      api_location_service_url(@location, @service),
      @attrs.merge!(service_areas: ['Belmont, CA'])
    )
    expect(response.status).to eq(422)
    expect(json['message']).to eq('Validation failed for resource.')
    expect(json['errors'].first['service_areas'].first).
      to eq('Belmont, CA is not a valid service area')
  end

  it 'does not change current value of Array attributes if passed in value is an empty String' do
    location = create(:nearby_loc)
    service = location.services.create!(attributes_for(:service_with_extra_whitespace))
    patch(
      api_location_service_url(location, service),
      @attrs.merge!(
        accepted_payments: '',
        funding_sources: '',
        keywords: '',
        languages: '',
        required_documents: '',
        service_areas: ''
      )
    )
    expect(response.status).to eq(200)
    array_attributes.each do |array_attribute|
      expect(json[array_attribute]).to eq expected_attributes[array_attribute.to_sym]
    end
  end

  it "doesn't allow updating a service without a valid token" do
    patch(
      api_location_service_url(@location, @service),
      @attrs,
      'HTTP_X_API_TOKEN' => 'invalid_token'
    )
    expect(response.status).to eq(401)
  end

  it 'updates search index when service changes', broken: true do
    # TODO: Need to fix pagincation logic in new search logic.
    patch(
      api_location_service_url(@location, @service),
      description: 'fresh tunes for the soul'
    )
    get api_search_index_url(keyword: 'yoga')
    expect(headers['X-Total-Count']).to eq '0'
  end
end

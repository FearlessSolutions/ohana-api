require 'rails_helper'

describe 'POST /locations/:location_id/services' do
  before do
    @loc = create(:location)
    @service_attributes = {
      name: 'test service',
      description: 'test description',
      status: 'active'
    }
  end

  it 'creates a service with valid attributes' do
    post(
      api_location_services_url(@loc),
      @service_attributes
    )
    expect(response.status).to eq(201)
    expect(json['name']).to eq(@service_attributes[:name])
  end

  it "doesn't create a service with invalid attributes" do
    post(
      api_location_services_url(@loc),
      website: 'belmont'
    )
    expect(response.status).to eq(422)
    expect(json['errors'].first['website']).to eq(['belmont is not a valid URL'])
  end

  it "doesn't allow creating a service without a valid token" do
    post(
      api_location_services_url(@loc),
      @service_attributes,
      'HTTP_X_API_TOKEN' => 'invalid_token'
    )
    expect(response.status).to eq(401)
    expect(json['message']).
      to eq('This action requires a valid X-API-Token header.')
  end
end

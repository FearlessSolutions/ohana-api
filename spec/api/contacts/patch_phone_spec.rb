require 'rails_helper'

describe 'PATCH Contact phone' do
  before do
    @location = create(:location)
    @contact = @location.contacts.create!(attributes_for(:contact))
    @phone = @contact.phones.create!(attributes_for(:phone))
    @attrs = { number: '123-456-7890', number_type: 'fax' }
  end

  describe 'PATCH /locations/:location_id/contacts/:contact_id/phones/:id' do
    it 'returns 200 when validations pass' do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs
      )
      expect(response).to have_http_status(200)
    end

    it 'returns the updated phone when validations pass' do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs
      )
      expect(json['number_type']).to eq 'fax'
    end

    it "updates the contact's phone" do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs
      )
      get api_location_url(@location)
      expect(json['contacts'].first['phones'].first['number']).to eq '123-456-7890'
    end

    it "doesn't add a new phone" do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs
      )
      expect(@contact.reload.phones.count).to eq(1)
    end

    it 'requires a valid phone id' do
      patch(
        api_location_contact_phone_url(@location, @contact, 123),
        @attrs
      )
      expect(response.status).to eq(404)
      expect(json['message']).
        to include 'The requested resource could not be found.'
    end

    it 'returns 422 when attribute is invalid' do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs.merge!(number: '703')
      )
      expect(response.status).to eq(422)
      expect(json['message']).to eq('Validation failed for resource.')
      expect(json['errors'].first).
        to eq('number' => ['703 is not a valid US phone or fax number'])
    end

    it "doesn't allow updating a phone without a valid token" do
      patch(
        api_location_contact_phone_url(
          @location, @contact, @phone
        ),
        @attrs,
        'HTTP_X_API_TOKEN' => 'invalid_token'
      )
      expect(response.status).to eq(401)
    end
  end
end

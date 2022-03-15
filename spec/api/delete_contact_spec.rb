require 'rails_helper'

describe 'DELETE /locations/:location_id/contacts/:id' do
  before do
    @loc = create(:location)
    @contact = @loc.contacts.create!(attributes_for(:contact))
  end

  it 'deletes the contact' do
    delete(
      api_location_contact_url(@loc, @contact),
      {}
    )
    expect(@loc.reload.contacts.count).to eq(0)
    expect(Contact.count).to eq(0)
  end

  it 'returns a 204 status' do
    delete(
      api_location_contact_url(@loc, @contact),
      {}
    )
    expect(response).to have_http_status(204)
  end

  it "doesn't allow deleting a contact without a valid token" do
    delete(
      api_location_contact_url(@loc, @contact),
      {},
      'HTTP_X_API_TOKEN' => 'invalid_token'
    )
    expect(response).to have_http_status(401)
  end
end

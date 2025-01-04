require 'rails_helper'

feature 'report_form_issue' do
  let(:dummy_loc) do
    class DummyLocation
      def name
        "dumy name"
      end
    end

    DummyLocation.new
  end

  context 'for signed in user' do
    setup do
      @user = create(:user)
      login_as @user
    end

    it "uses current user email as a placeholder in the email field", skip_ci: true do
      allow(Location).to receive(:get).and_return(dummy_loc)
      visit new_flag_path(resource_id: 1, resource_type: 'Location')

      input_field = find(:css, "#employee_of_the_org")
      expect(input_field["placeholder"]).to eq @user.email
    end
  end

  context 'for signed out user' do
    it "shows email field with a generic placeholder", skip_ci: true do
      allow(Location).to receive(:get).and_return(dummy_loc)
      visit new_flag_path(resource_id: 1, resource_type: 'Location')

      field_label = 'You must provide an email address and you agree to being contacted regarding the resource.'
      expect(find_field(field_label)["placeholder"]).to eq 'your.email@example.com'
    end
  end
end

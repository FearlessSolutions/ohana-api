require 'rails_helper'

feature 'Update email' do
  background do
    @org = create(:organization)
    login_super_admin
    visit '/admin/organizations/' + @org.slug
  end

  scenario 'with valid organization email' do
    fill_in 'organization_email', with: 'foo@bar.com'
    click_button I18n.t('admin.buttons.save_changes')
    expect(find_field('organization_email').value).to eq 'foo@bar.com'
  end

  scenario 'with invalid organization email' do
    fill_in 'organization_email', with: 'foobar.com'
    click_button I18n.t('admin.buttons.save_changes')
    expect(page).to have_content 'foobar.com is not a valid email'
  end
end

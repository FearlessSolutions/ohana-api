require 'rails_helper'

feature 'Update languages' do
  background do
    @loc = create_service.location
    login_super_admin
    visit '/admin/locations/' + @loc.slug
    click_link 'Literacy Program'
  end

  scenario 'with no languages' do
    click_button I18n.t('admin.buttons.save_changes')
    expect(@service.reload.languages).to eq []
  end

  skip 'with one language', :js do
    fill_in(placeholder: I18n.t('admin.services.forms.languages.placeholder'), with: "French\n")
    click_button I18n.t('admin.buttons.save_changes')
    expect(@service.reload.languages).to eq ['French']
  end

  scenario 'removing a language', :js do
    @service.update!(languages: %w[Arabic French])
    visit '/admin/locations/' + @loc.slug
    click_link 'Literacy Program'

    arabic = find('li', text: 'Arabic')
    arabic.find('span', text: "\u{00D7}").click

    click_button I18n.t('admin.buttons.save_changes')
    expect(@service.reload.languages).to eq ['French']
  end
end

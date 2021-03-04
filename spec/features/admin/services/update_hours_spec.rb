require 'rails_helper'

feature 'Update hours' do
  background do
    @location = create_service.location
    login_super_admin
    visit '/admin/locations/' + @location.slug
    click_link 'Literacy Program'
  end

  scenario 'with valid hours', :js do
    add_hour(
      weekday: 'Tuesday',
      opens_at_hour: '9 AM', opens_at_minute: '30',
      closes_at_hour: '5 PM', closes_at_minute: '45'
    )
    click_button I18n.t('admin.buttons.save_changes')

    prefix = 'service_regular_schedules_attributes_0'

    expect(find_field("#{prefix}_weekday").value).to eq '2'

    expect(find_field("#{prefix}_opens_at_4i").value).to eq '09'
    expect(find_field("#{prefix}_opens_at_5i").value).to eq '30'

    expect(find_field("#{prefix}_closes_at_4i").value).to eq '17'
    expect(find_field("#{prefix}_closes_at_5i").value).to eq '45'
  end

  scenario 'removing an hour', :js do
    @service.regular_schedules.create!(attributes_for(:regular_schedule))
    visit '/admin/locations/' + @location.slug
    click_link 'Literacy Program'

    prefix = 'service_regular_schedules_attributes_0'
    expect(find_field("#{prefix}_weekday").value).to eq '7'

    within '.hours' do
      click_link I18n.t('admin.buttons.delete_symbol')
    end
    click_button I18n.t('admin.buttons.save_changes')

    expect(page).to have_no_field("#{prefix}_weekday")
  end
end

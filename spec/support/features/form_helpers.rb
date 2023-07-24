module Features
  module FormHelpers
    def reset_accessibility
      within('.accessibility') do
        all('input[type=checkbox]').each do |checkbox|
          uncheck checkbox[:id]
        end
      end
      click_button I18n.t('admin.buttons.save_changes')
    end

    def set_all_accessibility
      within('.accessibility') do
        all('input[type=checkbox]').each do |checkbox|
          check checkbox[:id]
        end
      end
      click_button I18n.t('admin.buttons.save_changes')
    end

    def add_street_address(options = {})
      click_link I18n.t('admin.buttons.add_street_address')
      update_street_address(options)
      click_button I18n.t('admin.buttons.save_changes')
    end

    def update_street_address(options = {})
      fill_in 'location_address_attributes_address_1', with: options[:address_1]
      fill_in 'location_address_attributes_city', with: options[:city]
      fill_in 'location_address_attributes_state_province', with: options[:state_province]
      fill_in 'location_address_attributes_postal_code', with: options[:postal_code]
      fill_in 'location_address_attributes_country', with: options[:country]
      click_button I18n.t('admin.buttons.save_changes')
    end

    def add_mailing_address(options = {})
      click_link I18n.t('admin.buttons.add_mailing_address')
      update_mailing_address(options)
      click_button I18n.t('admin.buttons.save_changes')
    end

    def remove_street_address
      click_link I18n.t('admin.buttons.delete_street_address')
      click_button I18n.t('admin.buttons.save_changes')
    end

    def add_two_admins
      find_link(I18n.t('admin.buttons.add_admin')).click
      fill_in 'location[admin_emails][]', with: 'moncef@foo.com'
      find_link(I18n.t('admin.buttons.add_admin')).click
      admins = all(:xpath, "//input[contains(@name, '[admin_emails]')]")
      fill_in admins[-1][:id], with: 'moncef@otherlocation.com'
      click_button I18n.t('admin.buttons.save_changes')
    end

    def delete_all_admins
      find_link(I18n.t('admin.buttons.delete_admin'), match: :first).click
      find_link(I18n.t('admin.buttons.delete_admin'), match: :first).click


      # NOTE:
      # Currently, we are getting this following Selenium error:
      #`````````````````````````````````````````````````````````1
      # Selenium::WebDriver::Error::ElementClickInterceptedError:
      # element click intercepted: Element <input type="submit" name="commit" value="Save changes &amp; apply edits to database" class="btn btn-success" data-disable-with="Please wait...">
      # is not clickable at point (545, 563). Other element would receive the click: <div class="CodeMirror-scroll" tabindex="-1">...</div>
      #``````````````````````````````````````````````````````````
      # So added this hack temporarily but need a better way to fix this.
      page.execute_script("$('.CodeMirror').hide();")

      click_button I18n.t('admin.buttons.save_changes')
    end

    def fill_in_all_required_fields
      find('.select2', text: I18n.t('admin.shared.forms.choose_org.placeholder')).click
      all('input[type="search"]').last.fill_in(with: "Pare")
      find("li", text: "Parent Agency").click

      fill_in 'location_name', with: 'New Parent Agency location'
      fill_in_editor_field 'new description'
      expect(page).to have_editor_display text: 'new description'
      click_link I18n.t('admin.buttons.add_street_address')
      fill_in 'location_address_attributes_address_1', with: '123 Main St.'
      fill_in 'location_address_attributes_city', with: 'Belmont'
      fill_in 'location_address_attributes_state_province', with: 'CA'
      fill_in 'location_address_attributes_postal_code', with: '12345'
      fill_in 'location_address_attributes_country', with: 'US'
    end

    def fill_in_editor_field(text)
      within '.description' do
        within ".CodeMirror" do
          current_scope.click
          current_scope.find("textarea", visible: false).set(text)
        end
      end
    end

    def have_editor_display(**options)
      editor_display_locator = ".CodeMirror-code"
      have_css(editor_display_locator, **options)
    end

    def add_two_keywords
      click_link I18n.t('admin.buttons.add_keyword')
      fill_in 'service[keywords][]', with: 'homeless'
      click_link I18n.t('admin.buttons.add_keyword')
      keywords = page.
                 all(:xpath, "//input[@name='service[keywords][]']")
      fill_in keywords[-1][:id], with: 'CalFresh'
      click_button I18n.t('admin.buttons.save_changes')
    end

    def delete_all_keywords
      find_link(I18n.t('admin.buttons.delete_keyword'), match: :first).click
      find_link(I18n.t('admin.buttons.delete_keyword'), match: :first).click
      click_button I18n.t('admin.buttons.save_changes')
    end

    def add_two_service_areas
      click_link 'Add a new service area'
      fill_in 'service[service_areas][]', with: 'Belmont'
      click_link 'Add a new service area'
      service_areas = page.
                      all(:xpath, "//input[@name='service[service_areas][]']")
      fill_in service_areas[-1][:id], with: 'Atherton'
      click_button I18n.t('admin.buttons.save_changes')
    end

    def delete_all_service_areas
      find_link('Delete this service area permanently', match: :first).click
      find_link('Delete this service area permanently', match: :first).click
      click_button I18n.t('admin.buttons.save_changes')
    end

    def select_date(date, options = {})
      field = options[:from]
      select date.strftime('%Y'), from: "#{field}_1i"
      select date.strftime('%B'), from: "#{field}_2i"
      select date.strftime('%-d'), from: "#{field}_3i"
    end

    def fill_in_required_service_fields
      fill_in 'service_name', with: 'New VRS Services service'

      fill_in_editor_field 'new description'
      expect(page).to have_editor_display text: 'new description'


      page.execute_script("$('.CodeMirror').hide();")
    end
  end
end

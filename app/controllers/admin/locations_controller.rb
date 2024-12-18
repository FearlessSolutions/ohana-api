class Admin
  class LocationsController < ApplicationController
    include ActionView::Helpers::TextHelper
    before_action :authenticate_admin!
    before_action :get_date_range_options
    before_action :set_default_date_range
    layout 'admin'

    include Searchable

    def index
      @tags = Tag.all
      @search_terms = search_params(params)

      filtered_locations =
        Location.
          updated_between(@search_terms[:start_date], @search_terms[:end_date]).
          with_name(@search_terms[:keyword]).
          with_tag(@search_terms[:tag])

      all_locations = policy_scope(filtered_locations)
      @locations = Kaminari.paginate_array(all_locations).
                   page(params[:page]).per(params[:per_page])
    end

    def edit
      @location = Location.find(params[:id])
      @org = @location.organization
      @updated = @location.updated_at
      @number_visits_per_date_range = get_visits_per_date_range
      @number_updates_past_month = get_number_of_updates

      authorize @location
    end

    def archive
      if params[:archive].present?
        archive_selected_locations
      else
        redirect_to admin_services_url, alert: 'No services selected'
      end
    end

    def update
      @location = Location.find(params[:id])
      @location.assign_attributes(location_params)
      @org = @location.organization
      @number_visits_per_date_range = get_visits_per_date_range
      @number_updates_past_month = get_number_of_updates

      authorize @location

      if @location.save
        ahoy.track("Location Update", id: "#{@location.id}")
        redirect_to [:admin, @location],
                    notice: 'Location was successfully updated.'
      else
        render :edit
      end
    end

    def new
      @location = Location.new
      authorize @location
    end

    def create
      @location = Location.new(location_params)
      org = @location.organization

      authorize org if org.present?

      if @location.save
        redirect_to [:admin, @location], notice: 'Location was successfully created.'
      else
        render :new
      end
    end

    def destroy
      location = Location.find(params[:id])

      authorize location

      location.destroy
      redirect_to admin_locations_url
    end

    def capacity
      @locations = Kaminari.paginate_array(policy_scope(Location)).
                   page(params[:page]).per(params[:per_page])
      @locations.map! { |location| location.append(@location = Location.find(location[0])) }
    end

    def get_date_range_options
      @date_range_options = ['Yesterday', 'Last 7 Days', 'Last 30 Days', 'Last Month', 'Last Quarter', 'Last 12 Months']
    end

    def set_default_date_range
      @date_range = @date_range_options[2]
    end

    def get_number_of_updates
      today = Time.current.end_of_day
      one_month_ago = 1.month.ago.beginning_of_day
      Ahoy::Event.where(name: 'Location Update', properties: {id: "#{@location.id}"}, time: one_month_ago..today).count
    end

    def get_visits_per_date_range
      intervals = create_date_ranges
      times_visited = []
      intervals.each do |interval|
        times_visited <<
        Ahoy::Event.where(name: 'Location Visit', properties: {id: "#{@location.id}"}, time: interval).count
      end

      times_visited
    end

    def create_date_ranges
      todays_date= Date.current
      today = todays_date.to_time(:utc).beginning_of_day
      yesterday_end = Date.yesterday.to_time(:utc).end_of_day

      date_ranges = get_date_range_options
      intervals = []

      date_ranges.each do |date_range|
        case date_range
        when 'Yesterday'
          intervals << (Date.yesterday.to_time(:utc).beginning_of_day..yesterday_end)
        when 'Last 7 Days'
          intervals << ((today - 7.days)..yesterday_end)
        when 'Last 30 Days'
          intervals << ((today - 30.days)..yesterday_end)
        when 'Last Month'
          last_month = today.prev_month
          intervals << (last_month.beginning_of_month..last_month.end_of_month)
        when 'Last Quarter'
          prev_quarter = today.prev_quarter
          intervals << (prev_quarter.beginning_of_quarter..prev_quarter.end_of_quarter)
        when 'Last 12 Months'
          intervals << ((today.prev_year)..yesterday_end)
        end
      end

      intervals
    end

    private

    def archive_selected_locations
      Location.transaction do
        Location.find(params[:archive]).each do |location|
          location.update!(archived_at: Time.zone.now)
        end
      end
      redirect_to admin_locations_url,
                  notice: 'Archive successful.'
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_locations_url,
                  error: "Could not archive #{e.record.name}. Please deselect and try again."
    end

    # rubocop:disable MethodLength
    def location_params
      update_archived_at_params
      params.require(:location).permit(
        :organization_id, { accessibility: [] }, :active, { admin_emails: [] },
        :alternate_name, :archived_at, :description, :email, :featured, { languages: [] }, :latitude,
        { tag_list: [] }, :longitude, :name, :short_desc, :transportation, :website, :virtual, :audience,
        address_attributes: %i[
          address_1 address_2 city state_province postal_code country id _destroy
        ],
        phones_attributes: %i[
          country_prefix department extension number number_type vanity_number id _destroy
        ],
        regular_schedules_attributes: %i[weekday opens_at closes_at id _destroy],
        holiday_schedules_attributes: %i[label closed start_date end_date opens_at closes_at id _destroy],
        file_uploads_attributes: {}
      )
    end

    def update_archived_at_params
      if params['location']['archived_at'] == '1'
        params['location']['archived_at'] = Time.zone.now
      elsif params['location']['archived_at'] == '0'
        params['location']['archived_at'] = nil
      end
    end
    # rubocop:enable MethodLength
  end
end

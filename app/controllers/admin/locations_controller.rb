class Admin
  class LocationsController < ApplicationController
    include ActionView::Helpers::TextHelper
    before_action :authenticate_admin!
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
      @date_range_options = get_date_range_options
      @date_range = @date_range_options[2]
      @number_visits_per_date_range = query_number_of_visits
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

      authorize @location

      if @location.save
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
      ['Yesterday', 'Last 7 Days', 'Last 30 Days', 'Last Month', 'Last Quarter', 'Last 12 Months']
    end

    def query_number_of_visits
      intervals = createDateRanges
      times_visited = []
      intervals.each do |interval|
        times_visited <<
        Ahoy::Event.where(name: 'Location Visit', properties: {id: "#{@location.id}"}, time: interval).count
      end

      times_visited
    end

    def createDateRanges
      now = Time.now
      today = Time.utc(now.year, now.month, now.day)
      yesterday = today - 1

      last_month = Time.utc(now.year, now.month-1, now.day)
      current_quarter = Time.utc(now.year, now.month, now.day).beginning_of_quarter
      last_quarter =
        if current_quarter.month < 4
          Time.utc(current_quarter.year-1, 12, current_quarter.day)
        else
          Time.utc(current_quarter.year, current_quarter.month-1, current_quarter.day)
        end

      date_ranges = get_date_range_options
      intervals = []

      date_ranges.each do |date_range|
        case date_range
        when 'Yesterday'
          intervals << ((today - (60*60*24))..yesterday)
        when 'Last 7 Days'
          intervals << ((today - (60*60*24*7))..yesterday)
        when 'Last 30 Days'
          intervals << ((today - (60*60*24*30))..yesterday)
        when 'Last Month'
          intervals << (last_month.beginning_of_month..last_month.end_of_month)
        when 'Last Quarter'
          intervals << (last_quarter.beginning_of_quarter..last_quarter.end_of_quarter)
        when 'Last 12 Months'
          intervals << ((today - (60*60*24*365))..yesterday)
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

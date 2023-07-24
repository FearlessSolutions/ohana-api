class Admin
  class AnalyticsController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_start_and_end_dates

    layout 'admin'

    def index
      @start_date = DateTime.parse(params[:start_date] || '') rescue DateTime.today - 1.month
      @end_date = DateTime.parse(params[:end_date] || '') rescue DateTime.today

      @total_homepage_views = Ahoy::Visit.where(landing_page: root_url).count
      @new_homepage_views = Ahoy::Visit.
        where(landing_page: root_url).
        where(started_at: @start_date..@end_date).count

      @organizations_count = Organization.all.count
      @new_org_count = Organization.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
      @locations_count = Location.all.count
      @new_location_count = Location.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
      @services_count = Service.all.count
      @new_service_count = Service.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day).count
    end

    def update
      redirect_to action: :index, analytics: { start_date: @start_date, end_date: @end_date }
    end

    private

    def set_start_and_end_dates
      @start_date = analytics_params[:start_date].try(:to_date) || Date.today - 30.days
      @end_date = analytics_params[:end_date].try(:to_date) || Date.today
    end

    def analytics_params
      if params[:analytics].nil?
        {}
      else
        params.require('analytics').permit(:start_date, :end_date)
      end
    end
  end
end

class Admin
  class AnalyticsController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_start_and_end_dates

    layout 'admin'

    def index
      @landing_page = root_url
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

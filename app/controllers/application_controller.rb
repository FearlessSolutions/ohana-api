class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AhoyEventsHelper
  # Prevent CSRF attacks by raising an exception (with: :exception),
  protect_from_forgery with: :exception

  before_action :redirect_if_old

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, with: :render_not_found
    rescue_from Faraday::ConnectionFailed, with: :render_api_down
  end

  def after_sign_in_path_for(resource)
    return root_url if resource.is_a?(User)
    return admin_dashboard_url if resource.is_a?(Admin)
  end

  def after_sign_out_path_for(resource)
    return root_url if resource == :user
    return new_admin_session_url if resource == :admin
  end

  layout :layout_by_resource

  def pundit_user
    current_admin
  end


  private

  def render_not_found
    hash =
      {
        'status' => 404,
        'message' => 'The requested resource could not be found.',
        'documentation_url' => 'http://codeforamerica.github.io/ohana-api-docs/'
      }
    render json: hash, status: :not_found
  end

  def user_not_authorized
    flash[:error] = I18n.t('admin.not_authorized')
    redirect_to(request.referer || admin_dashboard_url)
  end

  def render_api_down
    redirect_to root_path, alert: t('errors.api_down')
  end

  def render_bad_search
    redirect_back fallback_location: root_path, alert: t('errors.bad_search')
  end

  protected

  def redirect_if_old
    if ENV['FORCE_DOMAIN_NAME'].present?
      if request.host != ENV['DOMAIN_NAME']
        redirect_to "https://#{ENV['DOMAIN_NAME']}#{request.fullpath}", status: 302, allow_other_host: true
      end
    end
  end

  def layout_by_resource
    return 'application' unless devise_controller? && resource_name == :admin

    'admin'
  end
end

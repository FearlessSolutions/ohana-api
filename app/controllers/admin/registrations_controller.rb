class Admin
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_permitted_parameters
    prepend_before_action :check_captcha, only: [:create]

    include PrivateRegistration

    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end

    def after_inactive_sign_up_url_for(_resource)
      new_admin_session_url
    end

    def after_update_path_for(_resource)
      edit_admin_registration_url
    end

    private
    def check_captcha
      success = verify_recaptcha(model: resource, minimum_score: 0.9, action: 'admin_register', secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'])
      checkbox_success = verify_recaptcha unless success
      if success || checkbox_success
        true
      else
        if !success
          @show_checkbox_recaptcha = true
        end
        respond_with_navigational(resource) do
          flash.discard(:recaptcha_error)
          render :new
        end
      end
    end
  end
end

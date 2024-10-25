class FeedbackController < ApplicationController
  def create
    if recaptcha_success
      FeedbackMailer.feedback_email(feedback_params).deliver_now
      redirect_to root_url, notice: 'Feedback Sent! Thank you!'
    else
      @user_agent = request.user_agent
      render :new
    end
  end

  private

  def feedback_params
    params.permit(:agent, :from, :message, :organization_name, :name)
  end

  def recaptcha_success
    success = verify_recaptcha(minimum_score: 0.9, action: 'submit_feedback', secret_key: ENV['RECAPTCHA_SECRET_KEY_V3'])
    checkbox_success = verify_recaptcha unless success
    if success || checkbox_success
      true
    else
      if !success
        @show_checkbox_recaptcha = true
      end
      false
    end
  end
end

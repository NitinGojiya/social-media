class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url, flash: { success: t("alerts.user_logged_in") }
    else
      redirect_to new_session_path, flash: { alert: "Try another email address or password." }
    end
  end

  def destroy
    reset_session
    terminate_session
    redirect_to new_session_path, flash: { success: t("alerts.user_logged_out") }
  end
end

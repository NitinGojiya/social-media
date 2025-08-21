class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]
  layout 'user_dashboard',only: [:profile]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome new user, #{@user.email_address}!"
    else
      flash.now[:alert] = "Create account failed"
      render :new, status: :unprocessable_content
    end
  end

  def profile
    @user = Current.session.user
  end

  def profile_create
    @user = Current.session.user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully!"  # Redirect here
    else
      flash.now[:alert] = "Failed to update profile."
      render :profile, status: :unprocessable_content
    end
  end

  def delete_profile
    @user = Current.session.user
    if @user.destroy
      redirect_to root_path, notice: "Profile deleted successfully!"
    else
      flash.now[:alert] = "Failed to delete profile."
      render :profile, status: :unprocessable_content
    end
  end

  def unlink_facebook
    user = Current.session.user
    if user.update(fb_page_id: nil, fb_page_token: nil)
      flash[:notice] = "Facebook account successfully unlinked."
    else
      flash[:alert] = "Failed to unlink Facebook account."
    end
    redirect_to profile_path
  end

  def unlink_instagram
    user = Current.session.user
    if user.update(ig_user_id: nil)
      flash[:notice] = "Instagram account successfully unlinked."
    else
      flash[:alert] = "Failed to unlink Instagram account."
    end
    redirect_to profile_path
  end

  def unlink_linkedin
    user = Current.session.user
    if user.update(linkedin_token: nil, linkedin_id: nil)
      user.linkedin_profiles.destroy_all
      flash[:notice] = "LinkedIn account successfully unlinked."
    else
      flash[:alert] = "Failed to unlink LinkedIn account."
    end
    redirect_to profile_path
  end

  def unlink_twitter
    user = Current.session.user
    if user.twitter_profile.destroy
      flash[:notice] = "Twitter account successfully unlinked."
    else
      flash[:alert] = "Failed to unlink Twitter account."
    end
    redirect_to profile_path
  end


  private
    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
    def profile_params
      params.require(:user).permit(:profile_photo)
    end
end

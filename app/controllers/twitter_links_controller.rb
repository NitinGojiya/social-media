class TwitterLinksController < ApplicationController
  def create
    user = Current.session.user  # ✅ assumes you’re using `Current` pattern
    auth = request.env['omniauth.auth']

    return redirect_to root_path, alert: 'Twitter auth failed' if auth.nil?

    if user.twitter_profile.present?
      # If profile exists, update it instead of trying to create it again
      user.twitter_profile.update!(
        name:     auth.info.name,
        nickname: auth.info.nickname,
        image:    auth.info.image,
        token:    auth.credentials.token,
        secret:   auth.credentials.secret
      )
    else
      #  If no profile yet, create one
      user.create_twitter_profile!(
        name:     auth.info.name,
        nickname: auth.info.nickname,
        image:    auth.info.image,
        token:    auth.credentials.token,
        secret:   auth.credentials.secret
      )
    end

    redirect_to root_path, notice: t('alerts.twitter_linked')
  end
end

class TwitterLinksController < ApplicationController
  def create
    user = Current.session.user
    auth = request.env['omniauth.auth']

    return redirect_to root_path, alert: 'Twitter auth failed' if auth.nil?
    profile_attrs = {
      name:         auth.info.name,
      nickname:     auth.info.nickname,
      image:        auth.info.image,
      token:        auth.credentials.token,   # still OAuth1
      secret:       auth.credentials.secret,  # still OAuth1
      bearer_token: auth.credentials.token    # from OAuth 2.0 flow
    }

    if user.twitter_profile.present?
      user.twitter_profile.update!(profile_attrs)
    else
      user.create_twitter_profile!(profile_attrs)
    end

    redirect_to root_path, notice: 'Twitter account linked successfully!'
  end
end

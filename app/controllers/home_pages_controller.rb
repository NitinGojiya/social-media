class HomePagesController < ApplicationController
 allow_unauthenticated_access only: %i[ index ]
  def index
  end

  def post
     @posts_future = Current.session.user.posts.scheduled.order(created_at: :desc)
     @posts_posted = Current.session.user.posts.posted.order(created_at: :desc)
  end
end

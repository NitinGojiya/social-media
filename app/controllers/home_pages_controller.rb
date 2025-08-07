class HomePagesController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  def index
  end

  def calendar_events
    posts = Current.session.user.posts

    events = posts.map do |post|
      {
        id: post.id,
        title: post.caption,
        start: post.scheduled_at.iso8601,
        image: post.photos.attached? ? url_for(post.photos.first) : nil,
        posted: post.status == 2
      }
    end

    # For holiday on calendar
    api_response = fetch_calendarific_data
    holiday_events = convert_holidays(api_response)
    render json: events + holiday_events
  end

  def post
    @posts_future = Current.session.user.posts.scheduled.order(scheduled_at: :asc)
    @posts_posted = Current.session.user.posts.posted.order(created_at: :desc)
    @user = Current.session.user
    @new_post = Current.session.user.posts.new
  end

  def link_account
    @user = Current.session.user
  end

  def calendar
    @user = Current.session.user
  end

  private
    def fetch_calendarific_data
      year = Time.zone.now.year
      response = HTTParty.get("https://calendarific.com/api/v2/holidays?&api_key=#{ENV['CALENDARIFIC_API_KEY']}&country=IN&year=#{year}")
      JSON.parse(response.body)
    end

    def convert_holidays(api_response)
      holidays = api_response.dig("response", "holidays") || []

      holidays.each_with_index.map do |holiday, index|
        {
          id: index,
          title: holiday["name"],
          start: holiday.dig("date", "iso"),
          holiday: true
        }
      end
    end
end

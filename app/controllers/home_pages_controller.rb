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

    # For holiday on calender just for feature in if any api for holiday

     holiday_events = [
      { "id": 0, "title": "New Year's Day", "start": "2025-01-01", "holiday": true },
      { "id": 1, "title": "Makar Sankranti / Pongal", "start": "2025-01-14", "holiday": true },
      { "id": 2, "title": "Republic Day", "start": "2025-01-26", "holiday": true },
      { "id": 3, "title": "Vasant Panchami", "start": "2025-02-02", "holiday": true },
      { "id": 4, "title": "Maha Shivaratri", "start": "2025-02-26", "holiday": true },
      { "id": 5, "title": "Ramadan Start", "start": "2025-03-02", "holiday": true },
      { "id": 6, "title": "Holika Dahana", "start": "2025-03-14", "holiday": true },
      { "id": 7, "title": "Holi", "start": "2025-03-15", "holiday": true },
      { "id": 8, "title": "Mahavir Jayanti", "start": "2025-04-10", "holiday": true },
      { "id": 9, "title": "Good Friday", "start": "2025-04-15", "holiday": true },
      { "id": 10, "title": "Eid‑ul‑Fitr (Ramzan)", "start": "2025-04-21", "holiday": true },
      { "id": 11, "title": "Labor Day", "start": "2025-05-01", "holiday": true },
      { "id": 12, "title": "Bakri Eid (Eid‑ul‑Adha)", "start": "2025-05-25", "holiday": true },
      { "id": 13, "title": "Rath Yatra", "start": "2025-06-06", "holiday": true },
      { "id": 14, "title": "Muharram", "start": "2025-07-06", "holiday": true },
      { "id": 15, "title": "Independence Day", "start": "2025-08-15", "holiday": true },
      { "id": 16, "title": "Janmashtami", "start": "2025-08-30", "holiday": true },
      { "id": 17, "title": "Gandhi Jayanti / Dussehra", "start": "2025-10-02", "holiday": true },
      { "id": 18, "title": "Diwali (Deepavali)", "start": "2025-10-31", "holiday": true },
      { "id": 19, "title": "Diwali Holiday (Govt)", "start": "2025-11-01", "holiday": true },
      { "id": 20, "title": "Guru Nanak Jayanti", "start": "2025-11-15", "holiday": true },
      { "id": 21, "title": "Christmas Day", "start": "2025-12-25", "holiday": true }
    ]

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
end

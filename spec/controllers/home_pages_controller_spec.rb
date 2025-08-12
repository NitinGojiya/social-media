# spec/controllers/home_pages_controller_spec.rb
require "rails_helper"

RSpec.describe HomePagesController, type: :controller do
  let(:user) { User.create!(email_address: "test@example.com", password: "Password@123") }

  before do
    allow(Current).to receive(:session).and_return(double(user: user))
  end

  describe "GET #index" do
  it "assigns @user when authenticated" do
    get :index
    expect(controller.instance_variable_get(:@user)).to eq(user)
    expect(response).to have_http_status(:ok)
  end
end

  describe "GET #calendar_events" do
    let!(:post1) do
      Post.create!(
        user: user,
        caption: "Future Post",
        scheduled_at: 1.day.from_now,
        status: 1
      )
    end

    before do
      allow(controller).to receive(:fetch_calendarific_data).and_return(
        {
          "response" => {
            "holidays" => [
              { "name" => "Test Holiday", "date" => { "iso" => "2025-01-01" } }
            ]
          }
        }
      )
    end

    it "returns events including holidays" do
      get :calendar_events
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      captions = json.map { |e| e["title"] }
      expect(captions).to include("Future Post", "Test Holiday")
    end
  end

  describe "GET #post" do
    let!(:future_post) do
      Post.create!(
        user: user,
        caption: "Scheduled Post",
        scheduled_at: 2.days.from_now,
        status: 1
      )
    end

    let!(:past_post) do
      Post.create!(
        user: user,
        caption: "Posted Post",
        scheduled_at: 2.days.ago,
        status: 2
      )
    end

    it "assigns scheduled and posted posts" do
      get :post
      expect(assigns(:posts_future)).to include(future_post)
      expect(assigns(:posts_posted)).to include(past_post)
      expect(assigns(:user)).to eq(user)
      expect(assigns(:new_post)).to be_a(Post)
    end
  end

  describe "GET #link_account" do
    it "assigns @user" do
      get :link_account
      expect(assigns(:user)).to eq(user)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #calendar" do
    it "assigns @user" do
      get :calendar
      expect(assigns(:user)).to eq(user)
      expect(response).to have_http_status(:ok)
    end
  end
end

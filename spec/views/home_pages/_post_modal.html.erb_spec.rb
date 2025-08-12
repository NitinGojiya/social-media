require 'rails_helper'

RSpec.describe "home_pages/_post_modal.html.erb", type: :view do
  # Helper method to build a user double with socials
  def build_user(ig_id:, fb_id:, li_id:, twitter_profile:)
    linkedin_profile_double = double(
      "LinkedinProfile",
      profile_picture_url: "http://example.com/pic.jpg",
      profile_name: "Test User",
      headline: "Software Engineer",
      name: "Test User"
    )

    double(
      "User",
      ig_user_id: ig_id,
      fb_page_id: fb_id,
      linkedin_id: li_id,
      twitter_profile: twitter_profile,
      linkedin_profiles: li_id ? [linkedin_profile_double] : []
    )
  end

  context "when user has all social accounts" do
    let(:ig_id) { "123" }
    let(:fb_id) { "456" }
    let(:li_id) { "789" }
    let(:twitter_profile_double) { double("TwitterProfile", name: "Test Twitter User", nickname: "Test123") }

    let(:user) do
      build_user(
        ig_id: ig_id,
        fb_id: fb_id,
        li_id: li_id,
        twitter_profile: twitter_profile_double
      )
    end

    before do
      assign(:user, user)
      render partial: "home_pages/post_modal"
    end

    it "renders the modal dialog" do
      expect(rendered).to have_selector("dialog#my_modal_1.modal")
    end

    it "renders the post form with caption and file inputs" do
      expect(rendered).to have_selector("form#postForm.post-form")
      expect(rendered).to have_selector("textarea[name='caption']")
      expect(rendered).to have_selector("input[type='file'][name='image_file']")
    end

    it "renders social media checkboxes for all platforms" do
      expect(rendered).to have_selector("input[name='post_to_ig']", visible: false)
      expect(rendered).to have_selector("input[name='post_to_fb']", visible: false)
      expect(rendered).to have_selector("input[name='post_to_li']", visible: false)
      expect(rendered).to have_selector("input[name='post_to_twitter']", visible: false)
    end

    it "does not show login buttons" do
      expect(rendered).not_to include("Login with Facebook")
      expect(rendered).not_to include("Login with X")
      expect(rendered).not_to include("Login with LinkedIn")
    end
  end

  context "when user is missing some social accounts" do
    let(:user) { build_user(ig_id: nil, fb_id: nil, li_id: nil, twitter_profile: nil) }

    before do
      assign(:user, user)
      render partial: "home_pages/post_modal"
    end

    it "does not render social media checkboxes" do
      expect(rendered).not_to have_selector("input[name='post_to_ig']")
      expect(rendered).not_to have_selector("input[name='post_to_fb']")
      expect(rendered).not_to have_selector("input[name='post_to_li']")
      expect(rendered).not_to have_selector("input[name='post_to_twitter']")
    end

    it "renders login buttons for missing accounts" do
      expect(rendered).to include("Login with Facebook")
      expect(rendered).to include("Login with X")
      expect(rendered).to include("Login with LinkedIn")
    end
  end

  context "schedule checkbox and datetime input" do
    let(:user) { build_user(ig_id: nil, fb_id: nil, li_id: nil, twitter_profile: nil) }

    before do
      assign(:user, user)
      render partial: "home_pages/post_modal"
    end

    it "renders the schedule checkbox and datetime input" do
      expect(rendered).to have_selector("input[type='checkbox'][name='is_schedule']")
      expect(rendered).to have_selector("input[type='datetime-local'][name='date']")
    end
  end

  context "post button" do
    let(:user) { build_user(ig_id: nil, fb_id: nil, li_id: nil, twitter_profile: nil) }

    before do
      assign(:user, user)
      render partial: "home_pages/post_modal"
    end

    it "renders the post button" do
      expect(rendered).to have_selector("button#postButton", text: "Post Now")
    end
  end
end

require 'rails_helper'

RSpec.describe "home_pages/post", type: :view do
  before do
    photos_with_pics = double("photos", attached?: true, each: [])

    assign(:posts_future, [
      double("Post",
        id: 144,
        caption: "twitter",
        scheduled_at: Time.now + 86400,
        photos: photos_with_pics,
        fb: 0,
        ig: 0,
        linkedin: 0,
        twitter: 1,
        status: 3,
        fb_post_id: nil,
        ig_post_id: nil,
        linkedin_post_urn: nil,
        twitter_post_id: "1954638676"
      )
    ])

    assign(:posts_posted, [
      double("Post",
        id: 146,
        caption: "Past Post 1",
        scheduled_at: Time.now - 86400,
        photos: double("photos", attached?: false),
        fb: 0,
        ig: 0,
        linkedin: 0,
        twitter: 1,
        status: 3,
        fb_post_id: nil,
        ig_post_id: nil,
        linkedin_post_urn: nil,
        twitter_post_id: "1954638676"
      )
    ])
  end

  it "renders the scheduled_post and posted_post partials" do
    allow(view).to receive(:render).and_call_original

    expect(view).to receive(:render).with('scheduled_post').and_call_original
    expect(view).to receive(:render).with('posted_post').and_call_original

    render
  end
end

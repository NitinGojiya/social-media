# spec/views/users/profile.html.erb_spec.rb
require 'rails_helper'

RSpec.describe "users/profile", type: :view do
  let(:user) { create(:user) }

  before do
    assign(:user, user)
  end

  it "displays the Settings title and manage account link" do
    render
    expect(rendered).to have_selector('h1', text: 'Settings')
    expect(rendered).to have_link('Manage your account', href: '#')
  end

  it "renders the Delete Account button" do
    render
    expect(rendered).to have_button('Delete Account')
    expect(rendered).to have_selector("form[action='#{Rails.application.routes.url_helpers.delete_profile_path}'][method='post']")
  end

  context "profile photo upload form" do
    it "renders file input and submit button" do
      render
      expect(rendered).to have_selector('input[type="file"][name="user[profile_photo]"]', visible: false)
      expect(rendered).to have_button('Save')
      expect(rendered).to have_selector('label[for="profile_photo_input"]', text: 'Choose')
    end

    it "shows current profile photo if attached" do
      user.profile_photo.attach(
        io: File.open(Rails.root.join('spec/fixtures/files/test_image.jpg')),
        filename: 'test_image.jpg',
        content_type: 'image/jpg'
      )
      render
      expect(rendered).to have_css('img.rounded-lg.shadow')
      expect(rendered).to match(/Current photo:/)
    end
  end

  context "linked accounts section" do
    it "renders linked accounts headings and buttons" do
      render

      %w[Instagram Facebook LinkedIn Twitter].each do |provider|
        expect(rendered).to have_selector('h2', text: 'Linked accounts')
        expect(rendered).to have_text(provider)
      end

      # Check Link or Unlink buttons presence (simplified)
      expect(rendered).to have_selector('button.px-4.py-1.bg-gray-100')
    end

    it "shows 'Link' links for unlinked accounts" do
      # user does not have linked accounts
      allow(user).to receive(:ig_user_id?).and_return(false)
      allow(user).to receive(:fb_page_id?).and_return(false)
      allow(user).to receive(:linkedin_id?).and_return(false)
      allow(user).to receive(:twitter_profile).and_return(false)

      render

      expect(rendered).to have_link('Link', href: '/auth/facebook')
      expect(rendered).to have_link('Link', href: '/auth/linkedin')
      expect(rendered).to have_link('Link', href: '/auth/twitter')
    end

    it "shows 'Unlink' button if account linked" do
      allow(user).to receive(:ig_user_id?).and_return(true)
      allow(user).to receive(:fb_page_id?).and_return(true)
      allow(user).to receive(:linkedin_id?).and_return(true)
      allow(user).to receive(:twitter_profile).and_return(true)

      render

      expect(rendered).to have_text('Unlink')
    end
  end
end

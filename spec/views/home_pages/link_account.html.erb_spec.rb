require 'rails_helper'

RSpec.describe "home_pages/link_account.html.erb", type: :view do
  before do
    render template: "home_pages/link_account"
  end

  it "renders the Facebook connect card with correct link and content" do
    expect(rendered).to have_link(href: "/auth/facebook")
    expect(rendered).to have_selector('div.bg-blue-600') # Facebook icon background
    expect(rendered).to have_text("Connect Now")
    expect(rendered).to match(/friends and family/i) # part of the Facebook description
  end

  it "renders the LinkedIn connect card with correct link and content" do
    expect(rendered).to have_link(href: "/auth/linkedin")
    expect(rendered).to have_selector('div.bg-blue-700') # LinkedIn icon background
    expect(rendered).to have_text("Connect Now")
    expect(rendered).to match(/professional content/i) # part of the LinkedIn description
  end

  it "renders the Twitter (X) connect card with correct link and content" do
    expect(rendered).to have_link(href: "/auth/twitter")
    expect(rendered).to have_selector('div.bg-black') # Twitter icon background
    expect(rendered).to have_text("Connect Now")
    expect(rendered).to match(/real-time conversations/i) # part of the Twitter description
  end
end

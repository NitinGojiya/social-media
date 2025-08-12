require 'rails_helper'

RSpec.describe "home_pages/index", type: :view do
  it "renders the hero partial content" do
    render
    expect(rendered).to include("Your gateway to next-gen content, creative tools, and universal storytelling.")
    expect(render).to include("Post Universal")
  end
end

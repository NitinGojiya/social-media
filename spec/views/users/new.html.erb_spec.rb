# spec/views/users/new.html.erb_spec.rb
require 'rails_helper'

RSpec.describe "users/new", type: :view do
  before do
    assign(:user, User.new)
  end

  it "renders the Create an Account heading" do
    render
    expect(rendered).to have_selector('h2', text: 'Create an Account')
  end

  it "renders the form with email, password, password_confirmation fields and submit button" do
    render

    expect(rendered).to have_selector('form')
    expect(rendered).to have_field('user_email_address', type: 'email')
    expect(rendered).to have_field('user_password', type: 'password')
    expect(rendered).to have_field('user_password_confirmation', type: 'password')
    expect(rendered).to have_button('Signup')
  end

    it "renders error messages when user has errors" do
    user_with_errors = User.new
    # Manually add errors to the user instance
    user_with_errors.errors.add(:email_address, "can't be blank")
    user_with_errors.errors.add(:password, "is too short")

    assign(:user, user_with_errors)

    render

    expect(rendered).to have_css('.bg-red-100.text-red-700')
    expect(rendered).to match(/can't be blank|is too short/)
    end

  it "renders the Google signup link" do
    render
    expect(rendered).to have_link('Signup with Google', href: '/auth/google_oauth2')
  end

  it "renders the login link" do
    render
    expect(rendered).to have_link('Log In', href: new_session_path)
  end
end

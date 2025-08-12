require 'rails_helper'

RSpec.describe "home_pages/calendar.html.erb", type: :view do
  before do
    render template: "home_pages/calendar"
  end

  it "includes the calendar div with data-controller attribute" do
    expect(rendered).to have_selector('div[data-controller="calendar"].min-h-screen')
  end

  it "includes the modal dialog with id and class" do
    expect(rendered).to have_selector('dialog#event_details_modal.modal')
  end
end

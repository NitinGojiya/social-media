require "rails_helper"

RSpec.describe SessionsController, type: :request do
  let(:user) { create(:user, password: "Password@123") }

  before do
    allow_any_instance_of(SessionsController).to receive(:after_authentication_url).and_return(root_path)
  end

  describe "GET /session/new" do
    it "renders login page" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "logs in and redirects" do
        post session_path, params: { email_address: user.email_address, password: "Password@123" }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Welcome back, #{user.email_address}!")
      end
    end

    context "with invalid credentials" do
      it "redirects back with alert" do
        post session_path, params: { email_address: user.email_address, password: "wrongpassword" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Try another email address or password.")
      end
    end

    context "with missing email or password" do
      it "redirects back with invalid alert if email blank" do
        post session_path, params: { email_address: "", password: "Password@123" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Try another email address or password.")
      end

      it "redirects back with invalid alert if password blank" do
        post session_path, params: { email_address: user.email_address, password: "" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Try another email address or password.")
      end
    end
  end
end

require "rails_helper"

RSpec.describe PasswordsController, type: :request do
  let!(:user) { create(:user, password: "Password@123") }
  let(:token) { user.signed_id(purpose: :password_reset, expires_in: 15.minutes) }

  describe "POST /passwords" do
    context "when user exists" do
      it "sends password reset email and redirects" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Password reset instructions sent")
      end
    end

    context "when user does not exist" do
      it "does not send email but still redirects" do
        expect {
          post passwords_path, params: { email_address: "unknown@example.com" }
        }.not_to change { ActionMailer::Base.deliveries.count }

        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Password reset instructions sent")
      end
    end
  end
  describe "PATCH /passwords/:token" do
    context "with matching passwords" do
        before do
        allow(User).to receive(:find_by_password_reset_token!).with(token).and_return(user)
        end

        it "updates password and redirects to new session" do
        patch password_path(token: token), params: { password: "Newpass@123", password_confirmation: "Newpass@123" }
        expect(response).to redirect_to(new_session_path)
        follow_redirect!
        expect(response.body).to include("Password has been reset")
        end
    end
    end
end

require "rails_helper"

RSpec.describe FacebookLinksController, type: :controller do
  let(:user) do
    User.create!(email_address: "test@example.com", password: "Password@123")
  end

  let(:token) { "fake_fb_access_token" }

  let(:session_double) { double("Session", user: user) }

  before do
    allow(Current).to receive(:session).and_return(session_double)
  end

  describe "GET #facebook_callback" do
    let(:auth_hash) do
      {
        "credentials" => { "token" => token }
      }
    end

    before do
      request.env["omniauth.auth"] = auth_hash
    end

    context "when a Facebook page is returned" do
      let(:pages_response) do
        {
          "data" => [
            { "id" => "page123", "name" => "My FB Page", "access_token" => "page_token_abc" }
          ]
        }.to_json
      end

      let(:ig_response) do
        {
          "instagram_business_account" => { "id" => "ig_user_456" }
        }.to_json
      end

      before do
        # Stub the first Facebook Pages API request
        allow(Net::HTTP).to receive(:get_response).with(
          URI("https://graph.facebook.com/v18.0/me/accounts?fields=name,access_token&access_token=#{token}")
        ).and_return(double(body: pages_response))

        # Stub the IG Business Account API request
        allow(Net::HTTP).to receive(:get_response).with(
          URI("https://graph.facebook.com/v18.0/page123?fields=instagram_business_account&access_token=#{token}")
        ).and_return(double(body: ig_response))
      end

      it "updates the user with Facebook and Instagram info" do
        get :facebook_callback

        user.reload
        expect(user.fb_token).to eq(token)
        expect(user.fb_page_id).to eq("page123")
        expect(user.fb_page_token).to eq("page_token_abc")
        expect(user.ig_user_id).to eq("ig_user_456")

        expect(response).to redirect_to(post_path)
        expect(flash[:notice]).to include("My FB Page")
      end
    end

    context "when no Facebook pages are found" do
      let(:pages_response) { { "data" => [] }.to_json }

      before do
        allow(Net::HTTP).to receive(:get_response).with(
          URI("https://graph.facebook.com/v18.0/me/accounts?fields=name,access_token&access_token=#{token}")
        ).and_return(double(body: pages_response))
      end

      it "redirects with an alert" do
        get :facebook_callback

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("No Facebook Pages found.")
      end
    end
  end
end

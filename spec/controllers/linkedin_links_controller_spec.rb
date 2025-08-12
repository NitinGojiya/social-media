require "rails_helper"

RSpec.describe LinkedinLinksController, type: :controller do
  let(:user) { User.create!(email_address: "test@example.com", password: "Password@123") }
  let(:client_id) { "test_client_id" }
  let(:client_secret) { "test_client_secret" }
  let(:app_host) { "http://example.com" }

   before do
    stub_const("LinkedinLinksController::LINKEDIN_CLIENT_ID", client_id)
    stub_const("LinkedinLinksController::LINKEDIN_CLIENT_SECRET", client_secret)
    stub_const("LinkedinLinksController::REDIRECT_URI", "#{app_host}/auth/linkedin/callback")
    allow(Current).to receive(:session).and_return(double(user: user))
    end


  describe "GET #auth" do
    it "redirects to LinkedIn authorization URL" do
      get :auth
      expect(response).to have_http_status(:found)
      expect(response.location).to include("https://www.linkedin.com/oauth/v2/authorization")
      expect(response.location).to include("client_id=#{client_id}")
     expect(response.location).to include("#{app_host}/auth/linkedin/callback")
    end
  end

  describe "GET #callback" do
    let(:code) { "test_code" }
    let(:access_token) { "fake_access_token" }
    let(:userinfo) do
      {
        "sub" => "linkedin_user_id",
        "name" => "John Doe",
        "headline" => "Software Engineer",
        "picture" => "http://example.com/pic.jpg"
      }
    end

    before do
      token_response = instance_double(HTTParty::Response, body: { access_token: access_token }.to_json)
      userinfo_response = instance_double(HTTParty::Response, parsed_response: userinfo)

      allow(HTTParty).to receive(:post)
        .with("https://www.linkedin.com/oauth/v2/accessToken", hash_including(:body, :headers))
        .and_return(token_response)

      allow(HTTParty).to receive(:get)
        .with("https://api.linkedin.com/v2/userinfo", hash_including(:headers))
        .and_return(userinfo_response)
    end

    it "updates the user with LinkedIn data and creates a linkedin_profile" do
      expect {
        get :callback, params: { code: code }
      }.to change { user.linkedin_profiles.count }.by(1)

      user.reload
      expect(user.linkedin_token).to eq(access_token)
      expect(user.linkedin_id).to eq("linkedin_user_id")

      profile = user.linkedin_profiles.last
      expect(profile.profile_name).to eq("John Doe")
      expect(profile.headline).to eq("Software Engineer")
      expect(profile.profile_picture_url).to eq("http://example.com/pic.jpg")

      expect(response).to redirect_to(post_path)
      expect(flash[:notice]).to include("John Doe")
    end
  end
end

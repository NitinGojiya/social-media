require 'rails_helper'

RSpec.describe TwitterLinksController, type: :controller do
  let(:user) { create(:user) }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'twitter',
      info: {
        name: "Test User",
        nickname: "testnick",
        image: "http://example.com/image.jpg"
      },
      credentials: {
        token: "token123",
        secret: "secret123"
      }
    )
  end

  before do
    # Stub Current.session.user to return our user
    allow(Current).to receive_message_chain(:session, :user).and_return(user)
    # Stub request.env['omniauth.auth'] with the mock auth hash
    request.env['omniauth.auth'] = auth_hash
  end

  describe "POST #create" do
    context "when user does not have a twitter_profile" do
      it "creates a new twitter_profile with the auth data" do
        expect(user.twitter_profile).to be_nil

        post :create

        profile = user.reload.twitter_profile
        expect(profile).not_to be_nil
        expect(profile.name).to eq("Test User")
        expect(profile.nickname).to eq("testnick")
        expect(profile.image).to eq("http://example.com/image.jpg")
        expect(profile.token).to eq("token123")
        expect(profile.secret).to eq("secret123")
        expect(profile.bearer_token).to eq("token123")
      end
    end

    context "when user already has a twitter_profile" do
      let!(:existing_profile) do
        create(:twitter_profile, user: user, name: "Old Name", token: "oldtoken", secret: "oldsecret", bearer_token: "oldbearer")
      end

      it "updates the existing twitter_profile with new auth data" do
        post :create

        existing_profile.reload
        expect(existing_profile.name).to eq("Test User")
        expect(existing_profile.nickname).to eq("testnick")
        expect(existing_profile.image).to eq("http://example.com/image.jpg")
        expect(existing_profile.token).to eq("token123")
        expect(existing_profile.secret).to eq("secret123")
        expect(existing_profile.bearer_token).to eq("token123")
      end
    end

    context "when omniauth.auth is missing" do
      before do
        request.env['omniauth.auth'] = nil
      end

      it "redirects to root_path with alert" do
        post :create
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Twitter auth failed")
      end
    end
  end
end

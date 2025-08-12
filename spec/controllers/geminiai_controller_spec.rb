require "rails_helper"

RSpec.describe GeminiaiController, type: :controller do
  let(:gemini_service) { instance_double(GeminiService) }
  let(:api_key) { "fake_gemini_key" }

    before do
    user = User.create!(email_address: "test@gmail.com", password: "Password@123")

    # Pretend we have a logged-in session
    allow(Current).to receive(:session).and_return(double(user: user))

    allow(ENV).to receive(:[]).with("GEMINI_API_KEY").and_return(api_key)
    allow(GeminiService).to receive(:new).with(api_key).and_return(gemini_service)
    end

  describe "POST #generate_caption" do
    context "when prompt is provided" do
      it "returns a caption from GeminiService" do
        allow(gemini_service).to receive(:generate_post_and_hashtags)
          .with("Hello AI").and_return("Post: This is generated text")

        post :generate_caption, params: { prompt: "Hello AI" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["caption"]).to eq("This is generated text")
      end
    end

    context "when prompt is missing" do
      it "uses the default prompt" do
        allow(gemini_service).to receive(:generate_post_and_hashtags)
          .with("Write a social media post").and_return("Post: Default text")

        post :generate_caption, params: {}

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["caption"]).to eq("Default text")
      end
    end

    context "when GeminiService raises an error" do
      it "returns a service unavailable error" do
        allow(gemini_service).to receive(:generate_post_and_hashtags)
          .and_raise(StandardError, "API down")

        post :generate_caption, params: { prompt: "Test error" }

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["error"]).to eq("API down")
      end
    end
  end
end

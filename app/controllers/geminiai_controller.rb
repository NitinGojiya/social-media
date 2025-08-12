class GeminiaiController < ApplicationController
  def generate_caption
    prompt = params[:prompt].presence || "Write a social media post"

    gemini = GeminiService.new(ENV["GEMINI_API_KEY"])

    begin
      caption = gemini.generate_post_and_hashtags(prompt)
      caption.gsub!(/^post:\s*/i, "")

      render json: { caption: caption }, status: :ok

    rescue => e
      Rails.logger.error("Gemini API Error: #{e.message}")
      render json: { error: e.message }, status: :service_unavailable
    end
  end
end

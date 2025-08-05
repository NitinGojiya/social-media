class GeminiService
  include HTTParty
  base_uri 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

  def initialize(api_key)
    @api_key = api_key
  end

  # Method to handle API request with retries
  def generate_post_and_hashtags(prompt)
    retries = 3
    begin
      response = self.class.post(
        '',
        headers: {
          'Content-Type' => 'application/json',
          'X-goog-api-key' => @api_key
        },
        body: {
          contents: [
            {
              parts: [
                {
                  text: <<~PROMPT
                    Create one common social media post about: "#{prompt}".
                    Then, generate 5 relevant and popular hashtags for this post.
                    The hashtags should be relevant to the topic and should not exceed 30 characters each.

                    Format the result like this:
                    post:

                    #tag1 #tag2 #tag3 #tag4 #tag5

                    Only return this content. Do not explain anything.
                  PROMPT
                }
              ]
            }
          ]
        }.to_json
      )

      if response.success?
        return response["candidates"][0]["content"]["parts"][0]["text"]
      else
        handle_error(response)
      end

    rescue Timeout::Error, Errno::ECONNREFUSED => e
      handle_network_error(e)
    rescue => e
      raise "Unexpected error: #{e.message}"
    end
  end

  # Custom error handler for API errors
  private

  def handle_error(response)
    case response.code
    when 503
      raise "Gemini API is currently overloaded. Please try again later."
    when 404
      raise "Requested model not found."
    when 500
      raise "Gemini API internal server error."
    else
      raise "Gemini API Error: #{response.body}"
    end
  end

  def handle_network_error(error)
    raise "Network error occurred: #{error.message}. Please check your connection or try again later."
  end
end

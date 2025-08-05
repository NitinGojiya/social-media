class GeminiService
  include HTTParty
  base_uri 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent'

  def initialize(api_key)
    @api_key = api_key
  end

  def generate_post_and_hashtags(prompt)
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
      raise "Gemini API Error: #{response.body}"
    end
  end
end

FactoryBot.define do
  factory :twitter_profile do
    association :user
    name { "Test Twitter Name" }
    nickname { "testnick" }
    image { "http://example.com/image.jpg" }
    token { "token123" }
    secret { "secret123" }
    bearer_token { "token123" }
  end
end

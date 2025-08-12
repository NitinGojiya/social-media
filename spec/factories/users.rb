# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email_address { "test@example.com" } # match controller param
    password { "Password@123" }          # <-- raw password, passes validation
    password_confirmation { "Password@123" }  # <-- confirmation, if needed
    created_at { Time.current }
    updated_at { Time.current }
  end
end

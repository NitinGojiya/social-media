require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:linkedin_profiles).dependent(:destroy) }
    it { should have_one(:twitter_profile).dependent(:destroy) }
    it { should have_one_attached(:profile_photo) }
  end

  describe 'validations' do
    subject { User.new(email_address: "test@example.com", password: "Password1!") }

    it { should validate_uniqueness_of(:email_address).case_insensitive }

    context 'password validations' do
      it 'is required on create' do
        user = User.new(email_address: "newuser@example.com", password: nil)
        expect(user.valid?).to be false
        expect(user.errors[:password]).to include("can't be blank")
      end

      it 'accepts valid password format' do
        user = User.new(email_address: "valid@example.com", password: "GoodPass1!")
        user.validate
        expect(user.errors[:password]).to be_empty
      end

      it 'rejects invalid password format' do
        user = User.new(email_address: "invalid@example.com", password: "badpass")
        user.validate
        expect(user.errors[:password]).to include(
          "must be at least 8 characters long and include one uppercase letter, one lowercase letter, and one symbol"
        )
      end

      it 'allows password to be nil on update' do
        user = User.create!(email_address: "update@example.com", password: "Password1!")
        user.password = nil
        expect(user.valid?).to be false
      end
    end
  end

  describe 'email_address uniqueness' do
  it 'does not allow duplicate email addresses (case insensitive)' do
    User.create!(email_address: "test@example.com", password: "Password1!")

    user_with_same_email = User.new(email_address: "TEST@example.com", password: "Password1!")

    expect(user_with_same_email).to_not be_valid
    expect(user_with_same_email.errors[:email_address]).to include("has already been taken")
  end

  it 'allows different email addresses' do
    User.create!(email_address: "unique@example.com", password: "Password1!")

    user_with_different_email = User.new(email_address: "different@example.com", password: "Password1!")

    expect(user_with_different_email).to be_valid
  end
end


  describe 'normalization' do
    it 'downcases and strips email_address' do
      user = User.new(email_address: "  Test@Example.COM  ", password: "Password1!")
      user.valid?
      expect(user.email_address).to eq("test@example.com")
    end
  end
end

require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:user) { User.create!(email_address: "user@example.com", password: "Password1!") }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many_attached(:photos) }
  end

  describe 'validations' do
    subject { Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now) }

    context 'scheduled_at' do
      it 'is invalid if scheduled_at is in the past when status is 1 (scheduled)' do
        subject.scheduled_at = 1.hour.ago
        subject.status = 1
        subject.valid?
        expect(subject.errors[:scheduled_at]).to include("must be in the future")
      end

      it 'is valid if scheduled_at is in the future' do
        subject.scheduled_at = 1.hour.from_now
        subject.status = 1
        expect(subject).to be_valid
      end

      it 'does not validate scheduled_at if status is not 1' do
        subject.status = 2
        subject.scheduled_at = 1.hour.ago
        expect(subject).to be_valid
      end
    end

    context 'media count and type validations' do
      before do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(1.megabyte)
      end

      it 'rejects posts with more than MAX_IMAGES images' do
        post = Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now)
        (Post::MAX_IMAGES + 1).times do |i|
          post.photos.attach(
            io: StringIO.new("image#{i}"), filename: "image#{i}.jpg", content_type: "image/jpeg"
          )
        end
        post.valid?
        expect(post.errors[:photos]).to include("can upload up to #{Post::MAX_IMAGES} images only")
      end

      it 'rejects posts with more than MAX_VIDEOS videos' do
        post = Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now)
        (Post::MAX_VIDEOS + 1).times do |i|
          post.photos.attach(
            io: StringIO.new("video#{i}"), filename: "video#{i}.mp4", content_type: "video/mp4"
          )
        end
        post.valid?
        expect(post.errors[:photos]).to include("only #{Post::MAX_VIDEOS} video allowed per post")
      end

      it 'rejects mixing images and videos' do
        post = Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now)
        post.photos.attach(
          io: StringIO.new("image"), filename: "image.jpg", content_type: "image/jpeg"
        )
        post.photos.attach(
          io: StringIO.new("video"), filename: "video.mp4", content_type: "video/mp4"
        )
        post.valid?
        expect(post.errors[:photos]).to include("cannot mix images and videos in the same post")
      end

      it 'rejects unsupported file types' do
        post = Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now)
        post.photos.attach(
          io: StringIO.new("file"), filename: "file.txt", content_type: "text/plain"
        )
        post.valid?
        expect(post.errors[:photos]).to include("contains an unsupported file type")
      end
    end

    context 'file size validation' do
      it 'rejects files exceeding max file size' do
        post = Post.new(user: user, status: 1, scheduled_at: 1.hour.from_now)
        big_content = "a" * (Post::MAX_FILE_SIZE_MB.megabytes + 1)
        post.photos.attach(
          io: StringIO.new(big_content), filename: "big_image.jpg", content_type: "image/jpeg"
        )
        post.valid?
        expect(post.errors[:photos].join).to include("exceeds #{Post::MAX_FILE_SIZE_MB} MB size limit")
      end
    end
  end

  describe 'callbacks' do
    it 'calls purge_later on photos before destroy' do
      post = Post.create!(user: user, status: 1, scheduled_at: 1.hour.from_now)
      post.photos.attach(
        io: StringIO.new("image"), filename: "image.jpg", content_type: "image/jpeg"
      )

      expect(post.photos).to be_attached

      expect(post.photos).to receive(:purge_later)
      post.destroy
    end
  end

  describe '#photo_urls' do
    it 'returns empty array if no photos attached' do
      post = Post.new(user: user)
      expect(post.photo_urls).to eq([])
    end

    it 'returns array of URLs for attached photos' do
      Rails.application.routes.default_url_options[:host] = 'http://test.host'
      post = Post.create!(user: user, status: 1, scheduled_at: 1.hour.from_now)
      post.photos.attach(
        io: StringIO.new("image"), filename: "image.jpg", content_type: "image/jpeg"
      )
      urls = post.photo_urls
      expect(urls).to all(include("http://test.host"))
      expect(urls.first).to include("image.jpg")
    end
  end
end

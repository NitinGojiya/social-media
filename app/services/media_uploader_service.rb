# app/services/media_uploader_service.rb
class MediaUploaderService
  attr_reader :file, :filepath

  def initialize(file)
    @file = file
    @filename = sanitize_filename(file.original_filename)
    @filepath = Rails.root.join("public", "uploads", unique_filename(@filename))
  end

  def upload_and_get_url
    FileUtils.mkdir_p(File.dirname(filepath))

    if video?
      File.open(filepath, "wb") { |f| f.write(file.read) }
    else
      process_image
    end

    "#{base_url}/uploads/#{File.basename(filepath)}"
  end

  private

  def sanitize_filename(name)
    name.gsub(/[^\w.\-]/, "_")
  end

  def unique_filename(name)
    "#{SecureRandom.uuid}_#{name}"
  end

  def base_url
    ENV.fetch("APP_HOST", "https://your-app.com")
  end

  def video?
    file.content_type.start_with?("video/")
  end

  def process_image
    require "mini_magick"
    image = MiniMagick::Image.read(file)
    aspect_ratio = image.width.to_f / image.height

    if aspect_ratio < 0.8
      new_height = (image.width / 0.8).round
      offset = ((image.height - new_height) / 2).round
      image.crop("#{image.width}x#{new_height}+0+#{offset}")
    elsif aspect_ratio > 1.91
      new_width = (image.height * 1.91).round
      offset = ((image.width - new_width) / 2).round
      image.crop("#{new_width}x#{image.height}+#{offset}+0")
    end

    image.resize "1080x1350>"
    image.write(filepath)
  end
end

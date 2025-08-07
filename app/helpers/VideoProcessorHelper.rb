require 'open3'

module VideoProcessorHelper
  def self.convert_to_instagram_reel(original_path)
    # Define output path
    output_path = Rails.root.join("tmp", "reel_#{SecureRandom.uuid}.mp4")

    # FFmpeg command to convert
    command = [
      "ffmpeg", "-y", "-i", original_path.to_s,
      "-c:v", "libx264",
      "-profile:v", "baseline",
      "-level", "3.1",
      "-pix_fmt", "yuv420p",
      "-vf", "scale=720:-2",
      "-r", "30",                     # Frame rate
      "-t", "90",                     # Max duration (seconds)
      "-c:a", "aac",
      "-b:a", "128k",
      "-movflags", "+faststart",
      output_path.to_s
    ]

    stdout, stderr, status = Open3.capture3(*command)

    unless status.success?
      Rails.logger.error("FFmpeg failed: #{stderr}")
      return nil
    end

    output_path
  end
end

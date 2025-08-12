require "streamio-ffmpeg"

module VideoProcessorHelper
  def self.convert_to_instagram_reel(original_path)
    movie = FFMPEG::Movie.new(original_path.to_s)

    return nil unless movie.valid?

    output_path = Rails.root.join("tmp", "reel_#{SecureRandom.uuid}.mp4").to_s

    options = {
      video_codec: "libx264",
      audio_codec: "aac",
      custom: %w[
        -profile:v baseline
        -level 3.1
        -pix_fmt yuv420p
        -vf scale=720:-2
        -r 30
        -t 90
        -b:a 128k
        -movflags +faststart
      ]
    }

    movie.transcode(output_path, options)

    File.exist?(output_path) ? output_path : nil
  rescue => e
    Rails.logger.error("FFMPEG gem failed: #{e.message}")
    nil
  end
end

class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  def not_found
    render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
  end
end

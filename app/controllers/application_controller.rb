class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_session!

  private

  # Finds or creates an AnonymousSession from the session cookie.
  # Returns the current AnonymousSession record tied to this browser session.
  def current_session
    @current_session ||= begin
      if session[:session_token].present?
        AnonymousSession.find_by(session_token: session[:session_token])
      end
    end
  end
  helper_method :current_session

  # Ensures an anonymous session exists before processing the request.
  # Redirects to the landing page if no session is found.
  def require_session!
    return if current_session.present?
    return if self.class == SessionsController

    redirect_to new_session_path, alert: "Please start a session first."
  end
end

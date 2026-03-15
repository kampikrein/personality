class SessionsController < ApplicationController
  skip_before_action :require_session!

  # GET /session/new
  # Landing page — the entry point for all anonymous users.
  def new
    # Render the landing / welcome page
  end

  # POST /session
  # Creates an anonymous session with a UUID, hashed IP + user agent,
  # stores the session_token in a Rails session cookie, and redirects
  # to assessment creation.
  def create
    fingerprint = Digest::SHA256.hexdigest(
      "#{request.remote_ip}:#{request.user_agent}"
    )

    anonymous_session = AnonymousSession.create!(
      session_token: SecureRandom.uuid,
      ip_fingerprint: fingerprint,
      started_at: Time.current
    )

    session[:session_token] = anonymous_session.session_token

    question_set = QuestionSet.current

    assessment = anonymous_session.assessments.create!(
      question_set: question_set,
      started_at: Time.current
    )

    first_question = assessment.question_set.questions.ordered.first

    redirect_to assessment_question_path(assessment, first_question)
  end
end

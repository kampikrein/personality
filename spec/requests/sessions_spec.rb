require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET / (root / sessions#new)" do
    it "renders the landing page successfully" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "includes the start button text" do
      get root_path

      expect(response.body).to include("시작하기")
    end
  end

  describe "POST /session" do
    it "creates an anonymous session" do
      expect {
        post session_path
      }.to change(AnonymousSession, :count).by(1)
    end

    it "stores the session_token in the Rails session" do
      post session_path

      token = AnonymousSession.last.session_token
      # The session cookie is set; subsequent requests in the same test session
      # will carry it automatically.
      expect(token).to be_present
    end

    it "creates an assessment and redirects to the first question" do
      post session_path

      assessment = Assessment.last
      first_question = assessment.question_set.questions.ordered.first
      expect(response).to redirect_to(assessment_question_path(assessment, first_question))
    end

    it "generates a UUID session token" do
      post session_path

      anonymous_session = AnonymousSession.last
      uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
      expect(anonymous_session.session_token).to match(uuid_regex)
    end

    it "records an ip_fingerprint as SHA-256 hash" do
      post session_path

      anonymous_session = AnonymousSession.last
      # The controller hashes remote_ip:user_agent — the hash should be 64 hex chars
      expect(anonymous_session.ip_fingerprint).to match(/\A[0-9a-f]{64}\z/)
    end
  end
end

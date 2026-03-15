require "rails_helper"

RSpec.describe "Full Assessment Flow", type: :request do
  # Seed the database to get the real QuestionSet and PersonalityTypes.
  # This ensures the scoring pipeline, profile composition, and insight
  # generation all work end-to-end against real data.
  before(:all) do
    Rails.application.load_seed
  end

  let(:question_set) { QuestionSet.current }
  let(:questions) { question_set.questions.active.ordered }

  # Helper: create a session + assessment and return the assessment ID.
  # POST /session now creates both the anonymous session and the assessment,
  # then redirects to the first question.
  def create_session_and_assessment!
    post session_path
    location = response.headers["Location"]
    match = location.match(%r{/assessments/(\d+)/questions/(\d+)})
    expect(match).to be_present, "Expected redirect to assessment question path, got: #{location}"
    match[1].to_i
  end

  # Helper: answer a single question.
  def answer_question(assessment_id, question_id, value: 3, response_time_ms: 2000)
    patch assessment_question_path(assessment_id, question_id),
          params: { response: { value: value, response_time_ms: response_time_ms } }
  end

  describe "complete user journey" do
    it "walks through session creation, assessment, all questions, submission, and results" do
      # ---------------------------------------------------------------
      # Step 1: POST /session — creates anonymous session + assessment
      # ---------------------------------------------------------------
      assessment_id = nil
      expect {
        assessment_id = create_session_and_assessment!
      }.to change(AnonymousSession, :count).by(1)
        .and change(Assessment, :count).by(1)

      anonymous_session = AnonymousSession.last
      expect(anonymous_session.session_token).to be_present

      assessment = Assessment.find(assessment_id)

      expect(assessment.status).to eq("in_progress")
      expect(assessment.current_question_index).to eq(0)
      expect(assessment.question_set).to eq(question_set)

      # ---------------------------------------------------------------
      # Step 3: Answer each question via PATCH /assessments/:id/questions/:qid
      # ---------------------------------------------------------------
      all_questions = questions.to_a
      expect(all_questions.size).to eq(20), "Expected 20 questions (4 domains x 5 each)"

      all_questions.each_with_index do |question, index|
        # Vary responses to get interesting type distribution
        # Positive polarity questions: alternate between 4 and 2
        # This creates a varied personality profile
        value = case question.domain
                when "energy"          then question.polarity == "positive" ? 4 : 2  # leans E
                when "decision_making" then question.polarity == "positive" ? 4 : 2  # leans N
                when "relationship"    then question.polarity == "positive" ? 4 : 2  # leans F
                when "recovery"        then question.polarity == "positive" ? 4 : 2  # leans P
                else 3
                end

        answer_question(assessment_id, question.id, value: value, response_time_ms: 2000 + (index * 100))

        if index < all_questions.size - 1
          # Should redirect to the next question
          expect(response).to have_http_status(:redirect)
          location = response.headers["Location"]
          expect(location).to include("/assessments/#{assessment_id}/questions/")
        else
          # Last question: should redirect to submit path
          expect(response).to have_http_status(:redirect)
        end
      end

      # Verify all responses were saved
      assessment.reload
      expect(assessment.responses.count).to eq(20)
      expect(assessment.current_question_index).to eq(20)

      # ---------------------------------------------------------------
      # Step 4: PATCH /assessments/:id/submit — submits the assessment
      # ---------------------------------------------------------------
      patch submit_assessment_path(assessment)

      expect(response).to have_http_status(:redirect)
      assessment.reload
      expect(assessment.status).to eq("submitted")

      # ---------------------------------------------------------------
      # Step 5: GET /results/:assessment_id — shows results
      # ---------------------------------------------------------------
      get result_path(assessment_id: assessment.id)

      expect(response).to have_http_status(:ok)

      # The scoring pipeline should have run inline
      assessment.reload
      expect(assessment.status).to eq("completed")

      # A profile should have been created
      profile = assessment.profile
      expect(profile).to be_present
      expect(profile.type_code).to be_present
      expect(PersonalityType::VALID_CODES).to include(profile.type_code)

      # The profile should have a personality type
      expect(profile.personality_type).to be_present
      expect(profile.personality_type.character_name_ko).to be_present

      # The response body should contain the type code and character name
      expect(response.body).to include(profile.type_code)
      expect(response.body).to include(profile.character_name_ko)

      # Domain scores should have been created
      expect(assessment.domain_scores.count).to eq(4)

      # Score vector should be populated
      expect(profile.score_vector).to be_present
      expect(profile.score_vector.keys.size).to eq(4)

      # Insights should have been generated
      expect(profile.insights.count).to eq(5)
      Insight::CONTEXTS.each do |context|
        insight = profile.insights.find_by(context: context)
        expect(insight).to be_present,
          "Expected insight for context '#{context}' to exist"
      end

      # Trust notice should be rendered
      expect(response.body).to include("공식 MBTI")
    end
  end

  describe "submitting with unanswered questions" do
    it "redirects back when not all questions are answered" do
      assessment_id = create_session_and_assessment!

      # Answer only the first question
      first_question = questions.first
      answer_question(assessment_id, first_question.id, value: 3)

      # Try to submit without answering all questions
      patch submit_assessment_path(assessment_id)

      # Should redirect back to the assessment (not to results)
      expect(response).to redirect_to(assessment_path(assessment_id))
      follow_redirect!
      expect(response.body).to include("answer all questions") if response.successful?
    end
  end

  describe "session requirement" do
    it "redirects to landing page when accessing assessments without a session" do
      post assessments_path

      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to landing page when accessing results without a session" do
      get result_path(assessment_id: 999)

      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "answer values are persisted correctly" do
    it "saves the response value and response_time_ms" do
      assessment_id = create_session_and_assessment!

      first_question = questions.first
      answer_question(assessment_id, first_question.id, value: 5, response_time_ms: 3500)

      response_record = Assessment.find(assessment_id).responses.find_by(question: first_question)
      expect(response_record).to be_present
      expect(response_record.value).to eq(5)
      expect(response_record.response_time_ms).to eq(3500)
      expect(response_record.sequence_number).to eq(0) # first question index
    end
  end
end

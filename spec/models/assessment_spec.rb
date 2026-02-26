require "rails_helper"

RSpec.describe Assessment, type: :model do
  let(:question_set) { create(:question_set, :with_questions) }
  let(:anonymous_session) { create(:anonymous_session) }
  let(:assessment) do
    create(:assessment,
      anonymous_session: anonymous_session,
      question_set: question_set,
      status: "in_progress",
      current_question_index: 0
    )
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(assessment).to be_valid
    end

    it "requires a status" do
      assessment.status = nil
      expect(assessment).not_to be_valid
    end

    it "only allows valid statuses" do
      Assessment::STATUSES.each do |status|
        assessment.status = status
        expect(assessment).to be_valid, "expected status '#{status}' to be valid"
      end
    end

    it "rejects invalid statuses" do
      assessment.status = "bogus"
      expect(assessment).not_to be_valid
    end
  end

  describe "status transitions" do
    it "starts as in_progress" do
      new_assessment = build(:assessment, question_set: question_set)
      new_assessment.valid?
      expect(new_assessment.status).to eq("in_progress")
    end

    it "transitions from in_progress to submitted via submit!" do
      expect(assessment.status).to eq("in_progress")

      assessment.submit!

      expect(assessment.reload.status).to eq("submitted")
    end

    it "transitions from submitted to scored via score!" do
      assessment.update!(status: "submitted")

      assessment.score!

      expect(assessment.reload.status).to eq("scored")
    end

    it "transitions from scored to completed via complete!" do
      assessment.update!(status: "scored")

      assessment.complete!

      expect(assessment.reload.status).to eq("completed")
    end

    it "transitions to failed via fail!" do
      assessment.update!(status: "scored")

      assessment.fail!

      expect(assessment.reload.status).to eq("failed")
    end

    it "goes through the full lifecycle: in_progress -> submitted -> scored -> completed" do
      expect(assessment.status).to eq("in_progress")

      assessment.submit!
      expect(assessment.status).to eq("submitted")

      assessment.score!
      expect(assessment.status).to eq("scored")

      assessment.complete!
      expect(assessment.status).to eq("completed")
    end
  end

  describe "#current_question" do
    it "returns the first question when index is 0" do
      first_question = question_set.questions.active.ordered.first

      expect(assessment.current_question).to eq(first_question)
    end

    it "returns the correct question after advancing the index" do
      assessment.update!(current_question_index: 3)

      expected_question = question_set.questions.active.ordered.offset(3).first
      expect(assessment.current_question).to eq(expected_question)
    end

    it "returns nil when the index is past the last question" do
      total = question_set.questions.active.count
      assessment.update!(current_question_index: total)

      expect(assessment.current_question).to be_nil
    end
  end

  describe "#total_questions" do
    it "returns the count of active questions in the question set" do
      # The :with_questions trait creates 4 domains x 5 questions = 20
      expect(assessment.total_questions).to eq(20)
    end

    it "excludes inactive questions" do
      question_set.questions.first.update!(active: false)

      expect(assessment.total_questions).to eq(19)
    end
  end

  describe "#progress_percentage" do
    it "returns 0 when no questions have been answered" do
      expect(assessment.progress_percentage).to eq(0)
    end

    it "returns 50 when halfway through" do
      total = assessment.total_questions
      assessment.update!(current_question_index: total / 2)

      expect(assessment.progress_percentage).to eq(50)
    end

    it "returns 100 when all questions are answered" do
      total = assessment.total_questions
      assessment.update!(current_question_index: total)

      expect(assessment.progress_percentage).to eq(100)
    end

    it "returns 0 when there are no questions" do
      empty_qs = create(:question_set)
      empty_assessment = create(:assessment,
        anonymous_session: anonymous_session,
        question_set: empty_qs
      )

      expect(empty_assessment.progress_percentage).to eq(0)
    end

    it "rounds to the nearest integer" do
      # With 20 questions and index at 1, that's 5%
      assessment.update!(current_question_index: 1)
      expect(assessment.progress_percentage).to eq(5)

      # With 20 questions and index at 3, that's 15%
      assessment.update!(current_question_index: 3)
      expect(assessment.progress_percentage).to eq(15)
    end
  end

  describe "#next_question!" do
    it "increments the current_question_index by 1" do
      expect {
        assessment.next_question!
      }.to change { assessment.reload.current_question_index }.from(0).to(1)
    end
  end

  describe "associations" do
    it "belongs to an anonymous_session" do
      expect(assessment.anonymous_session).to eq(anonymous_session)
    end

    it "belongs to a question_set" do
      expect(assessment.question_set).to eq(question_set)
    end

    it "has many responses" do
      expect(assessment).to respond_to(:responses)
    end

    it "has many domain_scores" do
      expect(assessment).to respond_to(:domain_scores)
    end

    it "has one profile" do
      expect(assessment).to respond_to(:profile)
    end
  end

  describe "scopes" do
    it ".in_progress returns only in_progress assessments" do
      create(:assessment, anonymous_session: anonymous_session, question_set: question_set, status: "completed")
      in_progress = create(:assessment, anonymous_session: anonymous_session, question_set: question_set, status: "in_progress")

      expect(Assessment.in_progress).to include(in_progress)
      expect(Assessment.in_progress.pluck(:status).uniq).to eq(["in_progress"])
    end

    it ".completed returns only completed assessments" do
      completed = create(:assessment, anonymous_session: anonymous_session, question_set: question_set, status: "completed")
      create(:assessment, anonymous_session: anonymous_session, question_set: question_set, status: "in_progress")

      expect(Assessment.completed).to include(completed)
      expect(Assessment.completed.pluck(:status).uniq).to eq(["completed"])
    end
  end

  describe "defaults" do
    it "sets default values on create" do
      new_assessment = Assessment.create!(
        anonymous_session: anonymous_session,
        question_set: question_set
      )

      expect(new_assessment.status).to eq("in_progress")
      expect(new_assessment.current_question_index).to eq(0)
      expect(new_assessment.completion_rate).to eq(0.0)
      expect(new_assessment.non_response_rate).to eq(0.0)
      expect(new_assessment.extreme_response_rate).to eq(0.0)
      expect(new_assessment.retry_token).to be_present
    end
  end
end

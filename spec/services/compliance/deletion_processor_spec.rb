# frozen_string_literal: true

require "rails_helper"

RSpec.describe Compliance::DeletionProcessor do
  describe "#call" do
    subject(:result) { described_class.new(deletion_request).call }

    let(:session) { create(:anonymous_session) }
    let(:deletion_request) { create(:deletion_request, anonymous_session: session) }

    context "with a full assessment chain" do
      let(:question_set) { create(:question_set, :with_questions) }
      let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }
      let(:personality_type) { PersonalityType.find_by(code: "ENFP") || create(:personality_type) }

      before do
        # Create responses
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 2000, sequence_number: i + 1)
        end

        # Create domain scores
        Question::DOMAINS.each do |domain|
          create(:domain_score, assessment: assessment, domain: domain)
        end

        # Create profile + insights
        profile = create(:profile, assessment: assessment,
                         anonymous_session: session, personality_type: personality_type)
        Insight::CONTEXTS.each do |ctx|
          create(:insight, profile: profile, context: ctx)
        end

        # Create consent
        create(:consent, anonymous_session: session)
      end

      it "returns success" do
        expect(result[:success]).to be true
      end

      it "deletes all responses" do
        result
        expect(Response.where(assessment_id: assessment.id).count).to eq(0)
      end

      it "deletes all domain scores" do
        result
        expect(DomainScore.where(assessment_id: assessment.id).count).to eq(0)
      end

      it "deletes all insights" do
        result
        expect(Insight.count).to eq(0)
      end

      it "deletes the profile" do
        result
        expect(Profile.count).to eq(0)
      end

      it "deletes assessments" do
        result
        expect(Assessment.where(anonymous_session_id: session.id).count).to eq(0)
      end

      it "deletes consents" do
        result
        expect(Consent.where(anonymous_session_id: session.id).count).to eq(0)
      end

      it "deletes the anonymous session" do
        result
        expect(AnonymousSession.find_by(id: session.id)).to be_nil
      end

      it "returns success indicating completion" do
        # Note: deletion_request itself may be destroyed via cascade
        # when anonymous_session is deleted, so we verify via the result
        expect(result[:success]).to be true
      end

      it "creates audit log entries" do
        expect { result }.to change(AuditLog, :count).by_at_least(3)
      end

      it "returns accurate deleted counts" do
        expect(result[:deleted_counts][:responses]).to eq(20) # 4 domains * 5 questions
        expect(result[:deleted_counts][:domain_scores]).to eq(4)
        expect(result[:deleted_counts][:insights]).to eq(5)
        expect(result[:deleted_counts][:profiles]).to eq(1)
        expect(result[:deleted_counts][:assessments]).to eq(1)
        expect(result[:deleted_counts][:consents]).to eq(1)
        expect(result[:deleted_counts][:anonymous_sessions]).to eq(1)
      end
    end

    context "with no assessments (minimal session)" do
      before do
        create(:consent, anonymous_session: session)
      end

      it "still succeeds" do
        expect(result[:success]).to be true
      end

      it "deletes the session and consent" do
        result
        expect(AnonymousSession.find_by(id: session.id)).to be_nil
        expect(Consent.where(anonymous_session_id: session.id).count).to eq(0)
      end
    end

    context "when an error occurs during deletion" do
      before do
        allow(session).to receive(:assessments).and_raise(StandardError, "DB error")
        allow(deletion_request).to receive(:anonymous_session).and_return(session)
      end

      it "returns failure" do
        expect(result[:success]).to be false
        expect(result[:error]).to eq("DB error")
      end

      it "transitions to failed" do
        result
        expect(deletion_request.reload.status).to eq("failed")
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::SpeedAnalyzer do
  describe "#call" do
    subject(:result) { described_class.new(assessment).call }

    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }

    context "with no timing data" do
      it "returns no-data result" do
        expect(result[:anomaly]).to be false
        expect(result[:flags]).to be_empty
        expect(result[:median_time_ms]).to be_nil
        expect(result[:fast_response_rate]).to eq(0.0)
      end
    end

    context "with normal response times" do
      before do
        # Ensure total assessment time is well above MIN_TOTAL_SECONDS (60s)
        assessment.update_columns(created_at: 5.minutes.ago, updated_at: Time.current)
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 2000 + (i * 100), sequence_number: i + 1)
        end
      end

      it "reports no anomaly" do
        expect(result[:anomaly]).to be false
        expect(result[:flags]).to be_empty
      end

      it "calculates median" do
        expect(result[:median_time_ms]).to be > 0
      end
    end

    context "with individual fast responses (< 500ms)" do
      before do
        questions = question_set.questions.active.ordered.to_a
        # One fast, rest normal
        create(:response, assessment: assessment, question: questions[0],
               value: 3, response_time_ms: 200, sequence_number: 1)
        questions[1..].each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 3000, sequence_number: i + 2)
        end
      end

      it "flags fast_individual" do
        expect(result[:flags]).to include(:fast_individual)
      end
    end

    context "with high fast rate (> 50% under 1000ms)" do
      before do
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 400, sequence_number: i + 1)
        end
      end

      it "flags both fast_individual and high_fast_rate" do
        expect(result[:anomaly]).to be true
        expect(result[:flags]).to include(:fast_individual, :high_fast_rate)
      end
    end

    context "with total time too short" do
      before do
        # Set assessment timestamps very close together
        assessment.update_columns(created_at: 30.seconds.ago, updated_at: Time.current)
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 2000, sequence_number: i + 1)
        end
      end

      it "flags fast_total_time" do
        expect(result[:flags]).to include(:fast_total_time)
      end
    end
  end
end

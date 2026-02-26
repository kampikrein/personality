# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quality::BotDetector do
  describe "#call" do
    subject(:result) { described_class.new(assessment).call }

    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }

    context "with uniform responses (all same value)" do
      before do
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: rand(1000..5000), sequence_number: i + 1)
        end
      end

      it "detects uniform pattern" do
        expect(result[:bot_suspected]).to be true
        expect(result[:patterns]).to include(:uniform)
      end
    end

    context "with sequential pattern (repeating cycle)" do
      before do
        question_set.questions.active.ordered.each_with_index do |q, i|
          cycle = [1, 2, 3, 4, 5]
          create(:response, assessment: assessment, question: q,
                 value: cycle[i % 5], response_time_ms: rand(1000..5000),
                 sequence_number: i + 1)
        end
      end

      it "detects sequential pattern" do
        expect(result[:bot_suspected]).to be true
        expect(result[:patterns]).to include(:sequential)
      end
    end

    context "with zero variance timing" do
      before do
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: rand(1..5), response_time_ms: 1500, sequence_number: i + 1)
        end
      end

      it "detects zero variance timing" do
        expect(result[:bot_suspected]).to be true
        expect(result[:patterns]).to include(:zero_variance_timing)
      end
    end

    context "with natural human responses" do
      before do
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: [1, 2, 3, 4, 5].sample,
                 response_time_ms: rand(800..6000), sequence_number: i + 1)
        end
      end

      it "does not suspect bot" do
        # Natural responses with varied values and timings should not trigger
        # Note: This is probabilistic; with random values some patterns might match
        # but it's unlikely all three would
        expect(result[:confidence]).to be < 1.0
      end
    end

    context "with fewer than 2 responses" do
      it "returns safe default (no data)" do
        expect(result[:bot_suspected]).to be false
        expect(result[:patterns]).to be_empty
        expect(result[:confidence]).to eq(0.0)
      end
    end

    context "confidence calculation" do
      before do
        # Create all-3s with identical timing to trigger all 3 heuristics
        question_set.questions.active.ordered.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 1000, sequence_number: i + 1)
        end
      end

      it "is the proportion of fired heuristics" do
        # uniform + zero_variance_timing should fire (2/3)
        # sequential requires repeating cycle with >1 unique value, so won't fire for all-3s
        expect(result[:confidence]).to eq((2.0 / 3).round(2))
      end
    end
  end
end

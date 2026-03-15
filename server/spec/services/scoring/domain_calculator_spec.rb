# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scoring::DomainCalculator do
  describe "#call" do
    subject(:result) { described_class.new(assessment).call }

    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }

    context "with positive polarity questions" do
      before do
        question_set.questions.where(domain: "energy").ordered.each_with_index do |q, i|
          # Ensure all energy questions are positive polarity
          q.update!(polarity: "positive")
          create(:response, assessment: assessment, question: q, value: 4,
                 response_time_ms: 2000, sequence_number: i + 1)
        end
      end

      it "sums values directly for positive polarity" do
        # 5 questions * value 4 = 20
        expect(result["energy"]).to eq(20)
      end
    end

    context "with negative polarity questions" do
      before do
        question_set.questions.where(domain: "decision_making").ordered.each_with_index do |q, i|
          q.update!(polarity: "negative")
          create(:response, assessment: assessment, question: q, value: 2,
                 response_time_ms: 2000, sequence_number: i + 100)
        end
      end

      it "reverse-scores using (6 - value)" do
        # 5 questions, each value=2, reversed => 6-2=4, total = 5*4 = 20
        expect(result["decision_making"]).to eq(20)
      end
    end

    context "with a mix of positive and negative polarity questions" do
      before do
        questions = question_set.questions.where(domain: "relationship").ordered.to_a
        # First 3 positive, last 2 negative
        questions[0..2].each { |q| q.update!(polarity: "positive") }
        questions[3..4].each { |q| q.update!(polarity: "negative") }

        questions.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q, value: 3,
                 response_time_ms: 2000, sequence_number: i + 200)
        end
      end

      it "sums positive directly and reverses negative" do
        # Positive: 3 questions * 3 = 9
        # Negative: 2 questions * (6-3) = 2 * 3 = 6
        # Total = 15
        expect(result["relationship"]).to eq(15)
      end
    end

    context "with skipped responses (nil value)" do
      before do
        questions = question_set.questions.where(domain: "recovery").ordered.to_a
        questions.each { |q| q.update!(polarity: "positive") }

        # Answer 3 out of 5 questions, skip 2
        questions[0..2].each_with_index do |q, i|
          create(:response, assessment: assessment, question: q, value: 5,
                 response_time_ms: 2000, sequence_number: i + 300)
        end
        questions[3..4].each_with_index do |q, i|
          create(:response, assessment: assessment, question: q, value: nil,
                 response_time_ms: 2000, sequence_number: i + 303)
        end
      end

      it "excludes skipped responses from the sum" do
        # 3 answered questions * 5 = 15 (the 2 nil responses are excluded)
        expect(result["recovery"]).to eq(15)
      end
    end

    context "with an empty assessment (no responses)" do
      it "returns 0 for all domains" do
        expect(result).to eq(
          "energy" => 0,
          "decision_making" => 0,
          "relationship" => 0,
          "recovery" => 0
        )
      end
    end

    context "return structure" do
      it "returns a hash with all four domain keys" do
        expect(result.keys).to contain_exactly("energy", "decision_making", "relationship", "recovery")
      end
    end

    context "with extreme values" do
      before do
        question_set.questions.where(domain: "energy").ordered.each_with_index do |q, i|
          q.update!(polarity: "positive")
          create(:response, assessment: assessment, question: q, value: 1,
                 response_time_ms: 2000, sequence_number: i + 400)
        end
      end

      it "sums all 1s correctly" do
        # 5 questions * 1 = 5
        expect(result["energy"]).to eq(5)
      end
    end

    context "with all maximum values" do
      before do
        question_set.questions.where(domain: "energy").ordered.each_with_index do |q, i|
          q.update!(polarity: "positive")
          create(:response, assessment: assessment, question: q, value: 5,
                 response_time_ms: 2000, sequence_number: i + 500)
        end
      end

      it "sums all 5s correctly" do
        # 5 questions * 5 = 25
        expect(result["energy"]).to eq(25)
      end
    end

    context "with negative polarity and value 1" do
      before do
        question_set.questions.where(domain: "energy").ordered.each_with_index do |q, i|
          q.update!(polarity: "negative")
          create(:response, assessment: assessment, question: q, value: 1,
                 response_time_ms: 2000, sequence_number: i + 600)
        end
      end

      it "reverse-scores to maximum (6-1=5)" do
        # 5 questions * (6-1) = 5 * 5 = 25
        expect(result["energy"]).to eq(25)
      end
    end

    context "with negative polarity and value 5" do
      before do
        question_set.questions.where(domain: "energy").ordered.each_with_index do |q, i|
          q.update!(polarity: "negative")
          create(:response, assessment: assessment, question: q, value: 5,
                 response_time_ms: 2000, sequence_number: i + 700)
        end
      end

      it "reverse-scores to minimum (6-5=1)" do
        # 5 questions * (6-5) = 5 * 1 = 5
        expect(result["energy"]).to eq(5)
      end
    end
  end
end

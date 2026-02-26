# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scoring::Normalizer do
  describe "#call" do
    subject(:result) { described_class.new(assessment, raw_scores).call }

    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }

    # Helper: create responses for a specific domain with the given value.
    # count defaults to 5 (all questions answered).
    def create_domain_responses(domain, value:, count: 5)
      questions = question_set.questions.where(domain: domain).ordered.limit(count).to_a
      questions.each_with_index do |q, i|
        q.update!(polarity: "positive")
        create(:response, assessment: assessment, question: q, value: value,
               response_time_ms: 2000, sequence_number: (domain.hash.abs + i) % 10_000)
      end
    end

    context "when all answers are 1 (minimum)" do
      let(:raw_scores) { { "energy" => 5 } }

      before { create_domain_responses("energy", value: 1) }

      it "normalizes to 0.0" do
        # raw=5, min=5, max=25, (5-5)/(25-5)*100 = 0.0
        expect(result["energy"]).to eq(0.0)
      end
    end

    context "when all answers are 5 (maximum)" do
      let(:raw_scores) { { "energy" => 25 } }

      before { create_domain_responses("energy", value: 5) }

      it "normalizes to 100.0" do
        # raw=25, min=5, max=25, (25-5)/(25-5)*100 = 100.0
        expect(result["energy"]).to eq(100.0)
      end
    end

    context "when all answers are 3 (midpoint)" do
      let(:raw_scores) { { "energy" => 15 } }

      before { create_domain_responses("energy", value: 3) }

      it "normalizes to 50.0" do
        # raw=15, min=5, max=25, (15-5)/(25-5)*100 = 50.0
        expect(result["energy"]).to eq(50.0)
      end
    end

    context "when only some questions are answered (partial answers)" do
      let(:raw_scores) { { "energy" => 9 } }

      before do
        # Answer only 3 out of 5 questions with value=3
        create_domain_responses("energy", value: 3, count: 3)
      end

      it "adjusts the normalization range proportionally" do
        # 3 answered: effective_min = 3*1 = 3, effective_max = 3*5 = 15
        # (9 - 3) / (15 - 3) * 100 = 6/12 * 100 = 50.0
        expect(result["energy"]).to eq(50.0)
      end
    end

    context "when no questions are answered for a domain" do
      let(:raw_scores) { { "energy" => 0 } }

      it "returns nil for that domain" do
        # No responses created, so answered_count = 0
        expect(result["energy"]).to be_nil
      end
    end

    context "with multiple domains" do
      let(:raw_scores) do
        {
          "energy" => 5,
          "decision_making" => 25,
          "relationship" => 15,
          "recovery" => 20
        }
      end

      before do
        create_domain_responses("energy", value: 1)
        create_domain_responses("decision_making", value: 5)
        create_domain_responses("relationship", value: 3)
        create_domain_responses("recovery", value: 4)
      end

      it "normalizes each domain independently" do
        expect(result["energy"]).to eq(0.0)
        expect(result["decision_making"]).to eq(100.0)
        expect(result["relationship"]).to eq(50.0)
        # raw=20, min=5, max=25, (20-5)/(25-5)*100 = 75.0
        expect(result["recovery"]).to eq(75.0)
      end
    end

    context "with partial answers at extreme values" do
      let(:raw_scores) { { "energy" => 10 } }

      before do
        # 2 questions answered with value 5
        create_domain_responses("energy", value: 5, count: 2)
      end

      it "normalizes using the proportional range" do
        # 2 answered: effective_min = 2*1 = 2, effective_max = 2*5 = 10
        # (10 - 2) / (10 - 2) * 100 = 100.0
        expect(result["energy"]).to eq(100.0)
      end
    end

    context "with a single answered question" do
      let(:raw_scores) { { "energy" => 3 } }

      before do
        create_domain_responses("energy", value: 3, count: 1)
      end

      it "normalizes with a single-item range" do
        # 1 answered: effective_min = 1, effective_max = 5
        # (3 - 1) / (5 - 1) * 100 = 2/4 * 100 = 50.0
        expect(result["energy"]).to eq(50.0)
      end
    end

    context "rounding" do
      let(:raw_scores) { { "energy" => 7 } }

      before do
        # 3 questions answered: create 3 responses with mixed values
        questions = question_set.questions.where(domain: "energy").ordered.limit(3).to_a
        values = [2, 2, 3]
        questions.each_with_index do |q, i|
          q.update!(polarity: "positive")
          create(:response, assessment: assessment, question: q, value: values[i],
                 response_time_ms: 2000, sequence_number: 900 + i)
        end
      end

      it "rounds to one decimal place" do
        # 3 answered: effective_min=3, effective_max=15
        # (7-3)/(15-3)*100 = 4/12*100 = 33.333... => 33.3
        expect(result["energy"]).to eq(33.3)
      end
    end
  end
end

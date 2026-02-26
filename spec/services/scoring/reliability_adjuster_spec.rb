# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scoring::ReliabilityAdjuster do
  describe "#call" do
    subject(:result) { described_class.new(assessment).call }

    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set) }

    context "return structure" do
      before { create_responses_for(assessment, value: 3) }

      it "returns expected keys" do
        expect(result.keys).to contain_exactly(
          :reliability_coefficient, :consistency_index, :speed_flag,
          :non_response_rate, :extreme_response_rate, :flags
        )
      end

      it "returns numeric values in valid ranges" do
        expect(result[:reliability_coefficient]).to be_between(0.0, 1.0)
        expect(result[:consistency_index]).to be_between(0.0, 1.0)
        expect(result[:non_response_rate]).to be_between(0.0, 1.0)
        expect(result[:extreme_response_rate]).to be_between(0.0, 1.0)
      end
    end

    context "with uniform responses (all 3s)" do
      before { create_responses_for(assessment, value: 3) }

      it "flags low consistency (zero variance means unmeasurable correlation)" do
        expect(result[:flags]).to include("low_split_half_consistency")
      end

      it "has no speed anomaly" do
        expect(result[:speed_flag]).to be false
      end

      it "has zero non-response rate" do
        expect(result[:non_response_rate]).to eq(0.0)
      end

      it "has 0.0 consistency index (all same values)" do
        expect(result[:consistency_index]).to eq(0.0)
      end
    end

    context "with all extreme values (1s and 5s)" do
      before do
        questions = question_set.questions.active.ordered.to_a
        questions.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: i.even? ? 1 : 5,
                 response_time_ms: 2000, sequence_number: i + 1)
        end
      end

      it "flags high extreme response rate" do
        expect(result[:extreme_response_rate]).to eq(1.0)
        expect(result[:flags]).to include("high_extreme_response_rate")
      end
    end

    context "with speed anomaly (>50% under 500ms)" do
      before do
        questions = question_set.questions.active.ordered.to_a
        questions.each_with_index do |q, i|
          create(:response, assessment: assessment, question: q,
                 value: 3, response_time_ms: 200, sequence_number: i + 1)
        end
      end

      it "flags speed anomaly" do
        expect(result[:speed_flag]).to be true
        expect(result[:flags]).to include("speed_anomaly")
      end
    end

    context "with high non-response rate (>20% skipped)" do
      before do
        questions = question_set.questions.active.ordered.to_a
        # Skip more than 20% of questions
        total = questions.size
        skip_count = (total * 0.3).ceil

        questions.each_with_index do |q, i|
          val = i < skip_count ? nil : 3
          create(:response, assessment: assessment, question: q,
                 value: val, response_time_ms: 2000, sequence_number: i + 1)
        end
      end

      it "flags high non-response rate" do
        expect(result[:non_response_rate]).to be > 0.2
        expect(result[:flags]).to include("high_non_response_rate")
      end
    end

    context "with no responses" do
      it "returns safe defaults" do
        expect(result[:consistency_index]).to eq(0.0)
        expect(result[:non_response_rate]).to eq(0.0)
        expect(result[:extreme_response_rate]).to eq(0.0)
        expect(result[:speed_flag]).to be false
      end
    end

    context "Pearson r mathematical correctness" do
      it "returns 1.0 for perfectly correlated halves" do
        adjuster = described_class.new(assessment)
        r = adjuster.send(:pearson_r, [1, 2, 3, 4, 5], [1, 2, 3, 4, 5])
        expect(r).to be_within(0.001).of(1.0)
      end

      it "returns -1.0 for perfectly inversely correlated halves" do
        adjuster = described_class.new(assessment)
        r = adjuster.send(:pearson_r, [1, 2, 3, 4, 5], [5, 4, 3, 2, 1])
        expect(r).to be_within(0.001).of(-1.0)
      end

      it "returns nil for constant arrays (zero variance)" do
        adjuster = described_class.new(assessment)
        r = adjuster.send(:pearson_r, [3, 3, 3], [3, 3, 3])
        expect(r).to be_nil
      end

      it "returns nil for arrays with fewer than 2 elements" do
        adjuster = described_class.new(assessment)
        expect(adjuster.send(:pearson_r, [1], [2])).to be_nil
      end
    end

    context "Spearman-Brown correction" do
      before { create_responses_for(assessment, value: 3) }

      it "applies 2r/(1+r) formula and clamps to [0,1]" do
        # With consistent data, consistency_index should be clamped between 0 and 1
        expect(result[:consistency_index]).to be_between(0.0, 1.0)
      end
    end

    context "reliability coefficient weighting" do
      before { create_responses_for(assessment, value: 3) }

      it "is a weighted average of sub-indicators" do
        # Verify it's the weighted sum: 0.4*consistency + 0.2*speed + 0.2*non_resp + 0.2*extreme
        coeff = result[:reliability_coefficient]
        expected = 0.4 * result[:consistency_index] +
                   0.2 * (result[:speed_flag] ? 0.0 : 1.0) +
                   0.2 * (1.0 - result[:non_response_rate]) +
                   0.2 * (1.0 - result[:extreme_response_rate])
        expect(coeff).to be_within(0.001).of(expected.round(3))
      end
    end
  end

  private

  def create_responses_for(assessment, value:)
    assessment.question_set.questions.active.ordered.each_with_index do |q, i|
      create(:response, assessment: assessment, question: q,
             value: value, response_time_ms: 2000, sequence_number: i + 1)
    end
  end
end

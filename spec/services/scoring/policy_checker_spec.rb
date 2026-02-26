# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scoring::PolicyChecker do
  describe "#call" do
    subject(:result) { described_class.new(assessment, reliability_result).call }

    let(:assessment) { create(:assessment, question_set: create(:question_set, :with_questions)) }

    context "when reliability coefficient is below threshold (< 0.3)" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.2,
          consistency_index: 0.3,
          speed_flag: false,
          non_response_rate: 0.1,
          extreme_response_rate: 0.2,
          flags: ["low_split_half_consistency"]
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end

      it "includes the reliability reason" do
        expect(result[:reasons]).to include("reliability_coefficient_below_threshold")
      end
    end

    context "when non-response rate is above threshold (> 0.5)" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.7,
          speed_flag: false,
          non_response_rate: 0.6,
          extreme_response_rate: 0.2,
          flags: ["high_non_response_rate"]
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end

      it "includes the non-response reason" do
        expect(result[:reasons]).to include("non_response_rate_above_threshold")
      end
    end

    context "when speed flag is true" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.7,
          speed_flag: true,
          non_response_rate: 0.05,
          extreme_response_rate: 0.2,
          flags: ["speed_anomaly"]
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end

      it "includes the speed anomaly reason" do
        expect(result[:reasons]).to include("speed_anomaly_detected")
      end
    end

    context "when all indicators are within acceptable range" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.75,
          speed_flag: false,
          non_response_rate: 0.05,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "does not block the assessment" do
        expect(result[:blocked]).to be false
      end

      it "returns no reasons" do
        expect(result[:reasons]).to be_empty
      end
    end

    context "when multiple blocking conditions are present" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.1,
          consistency_index: 0.2,
          speed_flag: true,
          non_response_rate: 0.8,
          extreme_response_rate: 0.9,
          flags: ["low_split_half_consistency", "speed_anomaly", "high_non_response_rate", "high_extreme_response_rate"]
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end

      it "includes all applicable reasons" do
        expect(result[:reasons]).to contain_exactly(
          "reliability_coefficient_below_threshold",
          "non_response_rate_above_threshold",
          "speed_anomaly_detected"
        )
      end
    end

    context "at boundary: reliability coefficient exactly 0.3" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.3,
          consistency_index: 0.5,
          speed_flag: false,
          non_response_rate: 0.1,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "does not block (threshold is strictly less than)" do
        expect(result[:blocked]).to be false
      end
    end

    context "at boundary: non-response rate exactly 0.5" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.7,
          speed_flag: false,
          non_response_rate: 0.5,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "does not block (threshold is strictly greater than)" do
        expect(result[:blocked]).to be false
      end
    end

    context "at boundary: reliability coefficient just below threshold (0.299)" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.299,
          consistency_index: 0.4,
          speed_flag: false,
          non_response_rate: 0.1,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end
    end

    context "at boundary: non-response rate just above threshold (0.501)" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.7,
          speed_flag: false,
          non_response_rate: 0.501,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "blocks the assessment" do
        expect(result[:blocked]).to be true
      end
    end

    context "return structure" do
      let(:reliability_result) do
        {
          reliability_coefficient: 0.8,
          consistency_index: 0.7,
          speed_flag: false,
          non_response_rate: 0.05,
          extreme_response_rate: 0.2,
          flags: []
        }
      end

      it "returns a hash with :blocked and :reasons keys" do
        expect(result).to include(:blocked, :reasons)
      end

      it "returns :reasons as an array" do
        expect(result[:reasons]).to be_an(Array)
      end
    end
  end
end

# frozen_string_literal: true

module Scoring
  # Determines whether an assessment's results should be blocked from display
  # based on data-quality policy rules.
  #
  # Blocking conditions (any one triggers a block):
  #   1. reliability_coefficient < 0.3   -- overall quality too low
  #   2. non_response_rate > 0.5         -- more than half the items skipped
  #   3. speed_flag detected AND > 50%   -- rushed through without reading
  #      of timed responses under 500ms
  #
  # Usage:
  #   result = Scoring::PolicyChecker.new(assessment, reliability_result).call
  #   # => { blocked: true, reasons: ["reliability_coefficient_below_threshold"] }
  #
  class PolicyChecker
    MIN_RELIABILITY = 0.3
    MAX_NON_RESPONSE_RATE = 0.5

    attr_reader :assessment, :reliability_result

    def initialize(assessment, reliability_result = nil)
      @assessment = assessment
      @reliability_result = reliability_result || Scoring::ReliabilityAdjuster.new(assessment).call
    end

    def call
      reasons = []

      reasons << "reliability_coefficient_below_threshold" if low_reliability?
      reasons << "non_response_rate_above_threshold"       if high_non_response?
      reasons << "speed_anomaly_detected"                  if speed_anomaly?

      {
        blocked: reasons.any?,
        reasons: reasons
      }
    end

    private

    def low_reliability?
      reliability_result[:reliability_coefficient] < MIN_RELIABILITY
    end

    def high_non_response?
      reliability_result[:non_response_rate] > MAX_NON_RESPONSE_RATE
    end

    def speed_anomaly?
      reliability_result[:speed_flag] == true
    end
  end
end

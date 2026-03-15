# frozen_string_literal: true

module Quality
  # Analyzes response timing for an assessment to flag suspiciously fast
  # completion that may indicate low-effort or automated responses.
  #
  # Flags generated:
  #   :fast_individual    - One or more responses were submitted in under
  #                         FAST_THRESHOLD_MS (500ms).
  #   :high_fast_rate     - More than FAST_RATE_THRESHOLD (50%) of responses
  #                         were under BULK_THRESHOLD_MS (1000ms).
  #   :fast_total_time    - The entire assessment was completed in under
  #                         MIN_TOTAL_SECONDS (60s).
  #
  # Usage:
  #   result = Quality::SpeedAnalyzer.new(assessment).call
  #   # => { anomaly: true, flags: [:fast_individual, :high_fast_rate],
  #   #      median_time_ms: 420, fast_response_rate: 0.65 }
  #
  class SpeedAnalyzer
    FAST_THRESHOLD_MS  = 500   # individual response floor
    BULK_THRESHOLD_MS  = 1_000 # threshold for the "bulk fast" check
    FAST_RATE_THRESHOLD = 0.5  # proportion that triggers the bulk flag
    MIN_TOTAL_SECONDS  = 60    # minimum plausible assessment duration

    attr_reader :assessment

    def initialize(assessment)
      @assessment = assessment
    end

    # @return [Hash] { anomaly: Boolean, flags: Array<Symbol>,
    #                  median_time_ms: Integer|nil, fast_response_rate: Float }
    def call
      timings = assessment.responses.answered.filter_map(&:response_time_ms)
      return no_data_result if timings.empty?

      flags = []
      flags << :fast_individual if any_below?(timings, FAST_THRESHOLD_MS)
      flags << :high_fast_rate  if fast_rate(timings) > FAST_RATE_THRESHOLD
      flags << :fast_total_time if total_time_too_short?

      median = median_value(timings)
      rate = fast_rate(timings)

      {
        anomaly: flags.any?,
        flags: flags,
        median_time_ms: median,
        fast_response_rate: rate.round(2)
      }
    end

    private

    def any_below?(timings, threshold)
      timings.any? { |t| t < threshold }
    end

    def fast_rate(timings)
      return 0.0 if timings.empty?

      fast_count = timings.count { |t| t < BULK_THRESHOLD_MS }
      fast_count.to_f / timings.size
    end

    def total_time_too_short?
      started = assessment.created_at
      finished = assessment.updated_at
      return false if started.nil? || finished.nil?

      (finished - started) < MIN_TOTAL_SECONDS
    end

    def median_value(sorted_timings)
      arr = sorted_timings.sort
      mid = arr.size / 2

      if arr.size.odd?
        arr[mid]
      else
        ((arr[mid - 1] + arr[mid]) / 2.0).round
      end
    end

    def no_data_result
      { anomaly: false, flags: [], median_time_ms: nil, fast_response_rate: 0.0 }
    end
  end
end

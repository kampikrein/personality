# frozen_string_literal: true

module Scoring
  # Evaluates the reliability of an assessment's responses.
  #
  # Four checks are performed:
  #
  # 1. Split-half consistency: Correlates odd-positioned vs even-positioned item
  #    scores within each domain. Low correlation suggests random or inattentive
  #    responding. Uses Spearman-Brown corrected Pearson r.
  #
  # 2. Speed anomalies: Flags when more than 50% of responses have a
  #    response_time_ms under 500ms, suggesting the respondent is clicking
  #    through without reading.
  #
  # 3. Non-response rate: Fraction of questions left unanswered (value: nil).
  #
  # 4. Extreme response rate: Fraction of answered questions where the value
  #    is 1 or 5, suggesting an acquiescence or extreme response bias.
  #
  # Returns:
  #   {
  #     reliability_coefficient: 0.82,
  #     consistency_index: 0.75,
  #     speed_flag: false,
  #     non_response_rate: 0.05,
  #     extreme_response_rate: 0.30,
  #     flags: ["high_extreme_response_rate"]
  #   }
  #
  class ReliabilityAdjuster
    SPEED_THRESHOLD_MS = 500
    SPEED_ANOMALY_RATIO = 0.5
    NON_RESPONSE_WARNING = 0.2
    EXTREME_RESPONSE_WARNING = 0.6

    attr_reader :assessment

    def initialize(assessment)
      @assessment = assessment
    end

    def call
      flags = []

      flags << "low_split_half_consistency" if consistency_index < 0.5
      flags << "speed_anomaly"              if speed_flag?
      flags << "high_non_response_rate"     if non_response_rate > NON_RESPONSE_WARNING
      flags << "high_extreme_response_rate" if extreme_response_rate > EXTREME_RESPONSE_WARNING

      {
        reliability_coefficient: reliability_coefficient,
        consistency_index: consistency_index,
        speed_flag: speed_flag?,
        non_response_rate: non_response_rate,
        extreme_response_rate: extreme_response_rate,
        flags: flags
      }
    end

    private

    # ------------------------------------------------------------------
    # Composite reliability: weighted average of sub-indicators, each in 0-1.
    # ------------------------------------------------------------------
    def reliability_coefficient
      @reliability_coefficient ||= begin
        weights = { consistency: 0.4, speed: 0.2, non_response: 0.2, extreme: 0.2 }

        score = 0.0
        score += weights[:consistency] * consistency_index
        score += weights[:speed]       * (speed_flag? ? 0.0 : 1.0)
        score += weights[:non_response] * (1.0 - non_response_rate)
        score += weights[:extreme]      * (1.0 - extreme_response_rate)

        score.round(3)
      end
    end

    # ------------------------------------------------------------------
    # Split-half consistency across all domains (averaged).
    # ------------------------------------------------------------------
    def consistency_index
      @consistency_index ||= begin
        domain_consistencies = Question::DOMAINS.filter_map do |domain|
          split_half_for(domain)
        end

        return 0.0 if domain_consistencies.empty?

        (domain_consistencies.sum / domain_consistencies.size).round(3)
      end
    end

    # Pearson r between odd- and even-positioned item scores within a domain,
    # corrected via Spearman-Brown prophecy formula: r_sb = 2r / (1 + r).
    def split_half_for(domain)
      domain_resp = responses_with_questions.select do |r|
        r.question.domain == domain && !r.skipped?
      end

      odd_values  = []
      even_values = []

      domain_resp.sort_by { |r| r.question.position }.each do |r|
        val = r.question.negative? ? (6 - r.value) : r.value
        if r.question.position.odd?
          odd_values << val
        else
          even_values << val
        end
      end

      # Need at least 2 items per half to compute a meaningful correlation.
      return nil if odd_values.size < 2 || even_values.size < 2

      # Truncate to equal length for pairing.
      min_len = [odd_values.size, even_values.size].min
      r = pearson_r(odd_values.first(min_len), even_values.first(min_len))

      return 0.0 if r.nil?

      # Spearman-Brown correction.
      corrected = (2.0 * r) / (1.0 + r)
      corrected.clamp(0.0, 1.0)
    end

    # ------------------------------------------------------------------
    # Speed anomaly detection.
    # ------------------------------------------------------------------
    def speed_flag?
      return @speed_flag if defined?(@speed_flag)

      @speed_flag = begin
        timed = responses_with_questions.select { |r| r.response_time_ms.present? }
        return false if timed.empty?

        fast_count = timed.count { |r| r.response_time_ms < SPEED_THRESHOLD_MS }
        (fast_count.to_f / timed.size) > SPEED_ANOMALY_RATIO
      end
    end

    # ------------------------------------------------------------------
    # Non-response rate.
    # ------------------------------------------------------------------
    def non_response_rate
      @non_response_rate ||= begin
        total = responses_with_questions.size
        return 0.0 if total.zero?

        skipped = responses_with_questions.count(&:skipped?)
        (skipped.to_f / total).round(3)
      end
    end

    # ------------------------------------------------------------------
    # Extreme response rate (1s and 5s among answered items).
    # ------------------------------------------------------------------
    def extreme_response_rate
      @extreme_response_rate ||= begin
        answered = responses_with_questions.reject(&:skipped?)
        return 0.0 if answered.empty?

        extremes = answered.count(&:extreme?)
        (extremes.to_f / answered.size).round(3)
      end
    end

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def responses_with_questions
      @responses_with_questions ||= assessment.responses.includes(:question).to_a
    end

    # Standard Pearson correlation coefficient for two equal-length arrays.
    def pearson_r(xs, ys)
      n = xs.size
      return nil if n < 2

      mean_x = xs.sum.to_f / n
      mean_y = ys.sum.to_f / n

      numerator   = 0.0
      denom_x_sq  = 0.0
      denom_y_sq  = 0.0

      n.times do |i|
        dx = xs[i] - mean_x
        dy = ys[i] - mean_y
        numerator  += dx * dy
        denom_x_sq += dx * dx
        denom_y_sq += dy * dy
      end

      denominator = Math.sqrt(denom_x_sq * denom_y_sq)
      return nil if denominator.zero?

      numerator / denominator
    end
  end
end

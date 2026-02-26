# frozen_string_literal: true

module Scoring
  # Normalizes raw domain scores to a 0-100 scale.
  #
  # With 5 questions per domain on a 5-point Likert scale:
  #   - Minimum possible raw score: 5  (all 1s)
  #   - Maximum possible raw score: 25 (all 5s)
  #
  # Formula: ((raw - min) / (max - min)) * 100
  #
  # Domains with no answered questions receive a normalized score of nil,
  # allowing downstream services to detect and handle incomplete data.
  #
  # Usage:
  #   raw_scores = { "energy" => 18, "decision_making" => 12, ... }
  #   result = Scoring::Normalizer.new(assessment, raw_scores).call
  #   # => { "energy" => 65.0, "decision_making" => 35.0, ... }
  #
  class Normalizer
    QUESTIONS_PER_DOMAIN = 5
    LIKERT_MIN = 1
    LIKERT_MAX = 5

    MIN_POSSIBLE = QUESTIONS_PER_DOMAIN * LIKERT_MIN  # 5
    MAX_POSSIBLE = QUESTIONS_PER_DOMAIN * LIKERT_MAX  # 25
    RANGE = MAX_POSSIBLE - MIN_POSSIBLE               # 20

    attr_reader :assessment, :raw_scores

    def initialize(assessment, raw_scores = nil)
      @assessment = assessment
      @raw_scores = raw_scores || Scoring::DomainCalculator.new(assessment).call
    end

    def call
      raw_scores.each_with_object({}) do |(domain, raw), normalized|
        normalized[domain] = normalize(domain, raw)
      end
    end

    private

    def normalize(domain, raw)
      answered = answered_count_for(domain)
      return nil if answered.zero?

      # When fewer than QUESTIONS_PER_DOMAIN were answered, scale min/max
      # proportionally so the 0-100 range remains meaningful.
      effective_min = answered * LIKERT_MIN
      effective_max = answered * LIKERT_MAX
      effective_range = effective_max - effective_min

      return 0.0 if effective_range.zero?

      (((raw - effective_min).to_f / effective_range) * 100).round(1)
    end

    def answered_count_for(domain)
      responses_by_domain[domain] || 0
    end

    def responses_by_domain
      @responses_by_domain ||=
        assessment.responses
                  .answered
                  .joins(:question)
                  .group("questions.domain")
                  .count
    end
  end
end

# frozen_string_literal: true

module Insights
  # Builds "why this suggestion" explanations by linking a profile's
  # score_vector to a specific suggestion.
  #
  # The design document requires every insight to include an explanation
  # block so users understand why a suggestion was surfaced for them.
  # This builder inspects the score_vector domains and generates a
  # human-readable rationale.
  #
  # Usage:
  #   explanation = Insights::ExplanationBuilder.new(score_vector, suggestion).call
  #   # => "Based on your energy tendency (72) and decision-making style (45), ..."
  #
  class ExplanationBuilder
    # Domain labels used in explanations, keyed by domain name.
    DOMAIN_LABELS = {
      "energy" => "energy tendency",
      "decision_making" => "decision-making style",
      "relationship" => "relationship orientation",
      "recovery" => "recovery pattern",
    }.freeze

    # Thresholds for describing score intensity.
    HIGH_THRESHOLD = 65
    LOW_THRESHOLD = 35

    attr_reader :score_vector, :suggestion

    def initialize(score_vector, suggestion)
      @score_vector = score_vector || {}
      @suggestion = suggestion.to_s
    end

    def call
      contributing_domains = identify_contributing_domains
      build_explanation(contributing_domains)
    end

    private

    def identify_contributing_domains
      score_vector.filter_map do |domain, score|
        label = DOMAIN_LABELS[domain.to_s]
        next unless label

        numeric_score = score.to_f
        intensity = describe_intensity(numeric_score)
        { domain: domain, label: label, score: numeric_score, intensity: intensity }
      end
    end

    def describe_intensity(score)
      if score >= HIGH_THRESHOLD
        "strong"
      elsif score <= LOW_THRESHOLD
        "moderate-to-low"
      else
        "balanced"
      end
    end

    def build_explanation(domains)
      return default_explanation if domains.empty?

      notable = domains.reject { |d| d[:intensity] == "balanced" }
      notable = domains.take(2) if notable.empty?

      domain_descriptions = notable.map do |d|
        "your #{d[:intensity]} #{d[:label]} (#{d[:score].round})"
      end

      "Based on #{domain_descriptions.join(' and ')}, " \
        "this suggestion may help you leverage your natural tendencies " \
        "and navigate areas that could benefit from attention."
    end

    def default_explanation
      "This suggestion is based on your overall profile pattern " \
        "and is intended as a starting point for self-reflection."
    end
  end
end

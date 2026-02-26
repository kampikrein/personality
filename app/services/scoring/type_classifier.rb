# frozen_string_literal: true

module Scoring
  # Converts 4 normalized domain scores into a 4-letter personality type code.
  #
  # Each domain maps to a dichotomy:
  #   - energy:          >= 50 -> E (Extraversion),  < 50 -> I (Introversion)
  #   - decision_making: >= 50 -> N (Intuition),     < 50 -> S (Sensing)
  #   - relationship:    >= 50 -> F (Feeling),       < 50 -> T (Thinking)
  #   - recovery:        >= 50 -> P (Perceiving),    < 50 -> J (Judging)
  #
  # Returns a hash with the composite type code and per-axis detail:
  #   {
  #     type_code: "ENFP",
  #     axes: {
  #       energy:          { letter: "E", score: 72.0 },
  #       decision_making: { letter: "N", score: 58.5 },
  #       relationship:    { letter: "F", score: 65.0 },
  #       recovery:        { letter: "P", score: 80.0 }
  #     }
  #   }
  #
  class TypeClassifier
    THRESHOLD = 50

    AXIS_MAP = {
      "energy"          => { high: "E", low: "I" },
      "decision_making" => { high: "N", low: "S" },
      "relationship"    => { high: "F", low: "T" },
      "recovery"        => { high: "P", low: "J" }
    }.freeze

    attr_reader :assessment, :normalized_scores

    def initialize(assessment, normalized_scores = nil)
      @assessment = assessment
      @normalized_scores = normalized_scores || Scoring::Normalizer.new(assessment).call
    end

    def call
      axes = {}
      type_letters = []

      AXIS_MAP.each do |domain, letters|
        score = normalized_scores[domain]
        letter = classify_axis(score, letters)

        axes[domain.to_sym] = { letter: letter, score: score }
        type_letters << letter
      end

      {
        type_code: type_letters.join,
        axes: axes
      }
    end

    private

    def classify_axis(score, letters)
      return letters[:low] if score.nil?

      score >= THRESHOLD ? letters[:high] : letters[:low]
    end
  end
end

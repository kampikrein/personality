# frozen_string_literal: true

module Insights
  # Generates learning style suggestions based on a profile's score_vector.
  #
  # Examines energy, decision_making, and recovery domains to surface
  # actionable recommendations for how users might approach learning and
  # skill development most effectively.
  #
  # Usage:
  #   result = Insights::LearningModule.new(profile).call
  #   # => { suggestions: [...], explanation: "..." }
  #
  class LearningModule
    attr_reader :profile

    def initialize(profile)
      @profile = profile
    end

    def call
      suggestions = build_suggestions
      explanation = build_explanation(suggestions)

      { suggestions: suggestions, explanation: explanation }
    end

    private

    def score_vector
      @score_vector ||= profile.score_vector || {}
    end

    def energy_score
      score_vector["energy"].to_f
    end

    def decision_making_score
      score_vector["decision_making"].to_f
    end

    def recovery_score
      score_vector["recovery"].to_f
    end

    def build_suggestions
      suggestions = []

      # Energy dimension: group vs. solo learning
      if energy_score >= 65
        suggestions << "You tend to learn well through discussion and interaction. " \
          "Study groups, teaching others, and talking through concepts " \
          "can deepen your understanding."
      elsif energy_score <= 35
        suggestions << "You tend to absorb information best through focused, " \
          "independent study. Creating a quiet, dedicated learning space " \
          "and allowing yourself processing time can enhance retention."
      else
        suggestions << "You tend to benefit from a mix of collaborative and solo " \
          "learning. Alternating between group discussions and individual " \
          "review sessions may be effective for you."
      end

      # Decision-making dimension: structured vs. exploratory learning
      if decision_making_score >= 65
        suggestions << "You may prefer systematic, step-by-step learning paths. " \
          "Outlines, structured courses, and clear milestones can help " \
          "you track progress and stay motivated."
      elsif decision_making_score <= 35
        suggestions << "You may enjoy exploring topics broadly before diving deep. " \
          "Mind maps, cross-disciplinary connections, and project-based " \
          "learning can play to this tendency."
      else
        suggestions << "Consider using structured frameworks as a starting point, " \
          "then allowing yourself tangents for deeper exploration when " \
          "a topic sparks your curiosity."
      end

      # Recovery dimension: learning pace and sustainability
      if recovery_score >= 65
        suggestions << "You tend to sustain focus across longer learning sessions. " \
          "Be mindful of diminishing returns — periodic review breaks " \
          "can actually improve long-term retention."
      elsif recovery_score <= 35
        suggestions << "Shorter, more frequent learning sessions with breaks " \
          "in between may suit your rhythm. Techniques like the Pomodoro " \
          "method can help maintain consistent progress."
      end

      # Learning style from PersonalityType if available
      if profile.learning_style.present?
        suggestions << profile.learning_style
      end

      suggestions
    end

    def build_explanation(suggestions)
      primary = suggestions.first.to_s
      Insights::ExplanationBuilder.new(score_vector, primary).call
    end
  end
end

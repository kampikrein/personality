# frozen_string_literal: true

module Insights
  # Generates recovery pattern suggestions based on a profile's score_vector.
  #
  # Examines the recovery domain primarily, supplemented by energy and
  # relationship scores, to produce actionable suggestions for how users
  # might recharge and maintain well-being. This is distinct from clinical
  # advice — suggestions are framed as self-reflection starting points.
  #
  # Usage:
  #   result = Insights::RecoveryModule.new(profile).call
  #   # => { suggestions: [...], explanation: "..." }
  #
  class RecoveryModule
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

    def relationship_score
      score_vector["relationship"].to_f
    end

    def recovery_score
      score_vector["recovery"].to_f
    end

    def build_suggestions
      suggestions = []

      # Primary recovery dimension
      if recovery_score >= 65
        suggestions << "You tend to recover relatively quickly from stress. " \
          "This resilience is a strength, but be mindful of pushing through " \
          "fatigue signals — proactive rest can prevent burnout."
      elsif recovery_score <= 35
        suggestions << "You may need more intentional recovery time after demanding " \
          "periods. Building regular restoration rituals into your schedule " \
          "(even small ones) can help maintain your energy over time."
      else
        suggestions << "Your recovery pattern is flexible. Pay attention to what " \
          "activities genuinely recharge you versus those that merely distract, " \
          "and prioritize the former."
      end

      # Energy dimension: how you recharge
      if energy_score >= 65
        suggestions << "Social activities may be part of how you recharge. " \
          "When feeling drained, consider connecting with people who " \
          "energize rather than deplete you."
      elsif energy_score <= 35
        suggestions << "Solitude and quiet are likely important to your recovery. " \
          "Protecting time for yourself — without guilt — is a form of " \
          "self-care that supports your overall functioning."
      end

      # Relationship dimension: recovery through connection
      if relationship_score >= 65
        suggestions << "You may recover well through meaningful conversations " \
          "and emotional connection. Having a trusted person to process " \
          "difficult experiences with can be especially restorative."
      elsif relationship_score <= 35
        suggestions << "Physical activities, hobbies, or structured routines " \
          "may be more restorative for you than emotional processing. " \
          "Finding your personal reset activity is worth the experiment."
      end

      # Recovery style from PersonalityType if available
      if profile.recovery_style.present?
        suggestions << profile.recovery_style
      end

      suggestions
    end

    def build_explanation(suggestions)
      primary = suggestions.first.to_s
      Insights::ExplanationBuilder.new(score_vector, primary).call
    end
  end
end

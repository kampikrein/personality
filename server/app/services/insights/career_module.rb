# frozen_string_literal: true

module Insights
  # Generates career direction suggestions based on a profile's score_vector.
  #
  # Examines all four domains (energy, decision_making, relationship, recovery)
  # to surface actionable suggestions about work environment preferences and
  # professional growth directions. Follows the design principle of behavioral
  # guidance rather than prescriptive career assignments.
  #
  # Usage:
  #   result = Insights::CareerModule.new(profile).call
  #   # => { suggestions: [...], explanation: "..." }
  #
  class CareerModule
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

    def relationship_score
      score_vector["relationship"].to_f
    end

    def recovery_score
      score_vector["recovery"].to_f
    end

    def build_suggestions
      suggestions = []

      # Energy dimension: work environment preference
      if energy_score >= 65
        suggestions << "You may thrive in roles with frequent interaction — " \
          "client-facing work, team coordination, or facilitation roles " \
          "can align with your energy style."
      elsif energy_score <= 35
        suggestions << "You may do your best work in roles that allow deep focus — " \
          "research, analysis, writing, or design roles where concentrated " \
          "effort is valued can suit your style."
      else
        suggestions << "Roles that blend independent deep work with periodic " \
          "collaboration may fit your energy pattern well. Look for " \
          "positions that offer this flexibility."
      end

      # Decision-making dimension: problem-solving approach
      if decision_making_score >= 65
        suggestions << "Your structured approach to decisions can be an asset in " \
          "roles requiring planning, operations, or systematic improvement. " \
          "Consider how you might also develop comfort with ambiguity."
      elsif decision_making_score <= 35
        suggestions << "Your openness to exploration can be valuable in creative, " \
          "innovation, or strategy roles. Building complementary habits " \
          "around follow-through can amplify this strength."
      end

      # Relationship dimension: people-oriented vs. task-oriented
      if relationship_score >= 65
        suggestions << "Your orientation toward people can be a strength in " \
          "mentoring, HR, community building, or customer success roles. " \
          "Ensure you also protect time for your own professional growth."
      elsif relationship_score <= 35
        suggestions << "Your focus on outcomes and systems can drive impact in " \
          "technical, analytical, or operational roles. Investing in " \
          "a few key professional relationships can expand opportunities."
      end

      # Recovery dimension: work pace and sustainability
      if recovery_score <= 35
        suggestions << "You may benefit from career environments with predictable " \
          "rhythms and adequate recovery time. Consider this when evaluating " \
          "high-intensity roles or startup cultures."
      end

      # Career hints from PersonalityType if available
      if profile.career_hints.present?
        suggestions << profile.career_hints
      end

      suggestions
    end

    def build_explanation(suggestions)
      primary = suggestions.first.to_s
      Insights::ExplanationBuilder.new(score_vector, primary).call
    end
  end
end

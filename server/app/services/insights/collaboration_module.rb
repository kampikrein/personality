# frozen_string_literal: true

module Insights
  # Generates collaboration suggestions based on a profile's score_vector.
  #
  # Examines energy and relationship domain scores to surface actionable
  # suggestions for working with others. Uses rule-based templates as the
  # MVP strategy (design doc: "start with rules + templates, expand
  # personalization later").
  #
  # Usage:
  #   result = Insights::CollaborationModule.new(profile).call
  #   # => { suggestions: [...], explanation: "..." }
  #
  class CollaborationModule
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

    def decision_making_score
      score_vector["decision_making"].to_f
    end

    def build_suggestions
      suggestions = []

      # Energy-based collaboration style
      if energy_score >= 65
        suggestions << "You tend to energize in group settings. " \
          "Consider initiating brainstorming sessions and being mindful " \
          "of quieter team members who may need space to contribute."
      elsif energy_score <= 35
        suggestions << "You tend to do your best thinking with time to reflect. " \
          "Consider requesting agendas in advance so you can prepare your " \
          "contributions before meetings."
      else
        suggestions << "You tend to adapt between collaborative and independent work. " \
          "Communicating your current preference to teammates can help " \
          "set mutual expectations."
      end

      # Relationship-based collaboration style
      if relationship_score >= 65
        suggestions << "Your orientation toward people and harmony can be a strength " \
          "in team coordination. Be aware that you may sometimes agree to " \
          "avoid friction — practice voicing constructive disagreements."
      elsif relationship_score <= 35
        suggestions << "Your focus on tasks and outcomes helps drive projects forward. " \
          "Consider scheduling brief check-ins with teammates to maintain " \
          "connection alongside productivity."
      end

      # Decision-making collaboration angle
      if decision_making_score >= 65
        suggestions << "You tend toward structured decision-making. When collaborating, " \
          "sharing your reasoning process can help others follow your logic " \
          "and build shared understanding."
      elsif decision_making_score <= 35
        suggestions << "You tend to be open to exploring multiple options. In team settings, " \
          "helping the group converge on decisions by summarizing trade-offs " \
          "can be especially valuable."
      end

      # Collaboration style from PersonalityType if available
      if profile.collaboration_style.present?
        suggestions << profile.collaboration_style
      end

      suggestions
    end

    def build_explanation(suggestions)
      primary = suggestions.first.to_s
      Insights::ExplanationBuilder.new(score_vector, primary).call
    end
  end
end

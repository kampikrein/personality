# frozen_string_literal: true

module Insights
  # Generates conflict coping suggestions based on a profile's score_vector.
  #
  # Examines relationship, decision_making, and recovery domains to produce
  # actionable suggestions for handling interpersonal friction. Follows the
  # design document's principle of behavioral guidance over labeling.
  #
  # Usage:
  #   result = Insights::ConflictModule.new(profile).call
  #   # => { suggestions: [...], explanation: "..." }
  #
  class ConflictModule
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

    def relationship_score
      score_vector["relationship"].to_f
    end

    def decision_making_score
      score_vector["decision_making"].to_f
    end

    def recovery_score
      score_vector["recovery"].to_f
    end

    def build_suggestions
      suggestions = []

      # Relationship dimension: harmony vs. directness
      if relationship_score >= 65
        suggestions << "You may tend to prioritize harmony, which can lead to " \
          "suppressing concerns. Try writing down your perspective before " \
          "a difficult conversation to clarify your needs."
      elsif relationship_score <= 35
        suggestions << "Your directness can be efficient in resolving issues. " \
          "Consider pausing to acknowledge the other person's feelings " \
          "before presenting your position — it often opens dialogue."
      else
        suggestions << "You tend to balance directness with sensitivity. " \
          "In conflicts, explicitly naming the issue while expressing " \
          "care for the relationship can leverage this balance."
      end

      # Decision-making dimension: structured vs. flexible
      if decision_making_score >= 65
        suggestions << "You may prefer to resolve conflicts through clear frameworks. " \
          "Remember that not everyone processes disagreements logically first — " \
          "emotional validation can be a necessary step before problem-solving."
      elsif decision_making_score <= 35
        suggestions << "You tend to be flexible in conflict, which allows creative " \
          "solutions. To avoid feeling overwhelmed, try setting a personal " \
          "boundary or bottom line before entering negotiations."
      end

      # Recovery dimension: how you recharge after conflict
      if recovery_score >= 65
        suggestions << "You tend to bounce back from friction relatively quickly. " \
          "Be mindful that others may need more time — check in rather than " \
          "assuming the issue is resolved."
      elsif recovery_score <= 35
        suggestions << "Conflicts may linger for you emotionally. Scheduling " \
          "deliberate recovery time (a walk, journaling, or a brief break) " \
          "after tense interactions can help you reset."
      end

      # Conflict style from PersonalityType if available
      if profile.conflict_style.present?
        suggestions << profile.conflict_style
      end

      suggestions
    end

    def build_explanation(suggestions)
      primary = suggestions.first.to_s
      Insights::ExplanationBuilder.new(score_vector, primary).call
    end
  end
end

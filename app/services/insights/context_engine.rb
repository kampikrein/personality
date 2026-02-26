# frozen_string_literal: true

module Insights
  # Routes to the appropriate insight module based on context, wraps the
  # result with ExplanationBuilder, and saves an Insight record.
  #
  # This is the primary entry point for generating insights. Callers pass
  # a profile and a context string (one of Insight::CONTEXTS), and the
  # engine dispatches to the correct module, enriches the explanation,
  # and persists the result.
  #
  # Usage:
  #   insight = Insights::ContextEngine.new(profile, "collaboration").call
  #   # => #<Insight context: "collaboration", suggestions: [...], explanation: "...">
  #
  class ContextEngine
    MODULES = {
      "collaboration" => Insights::CollaborationModule,
      "conflict" => Insights::ConflictModule,
      "learning" => Insights::LearningModule,
      "career" => Insights::CareerModule,
      "recovery" => Insights::RecoveryModule,
    }.freeze

    attr_reader :profile, :context

    def initialize(profile, context)
      @profile = profile
      @context = context.to_s
    end

    def call
      validate_context!

      mod = MODULES.fetch(context)
      result = mod.new(profile).call

      suggestions = result[:suggestions] || []
      explanation = enrich_explanation(result, suggestions)

      save_insight(suggestions, explanation)
    end

    private

    def validate_context!
      return if Insight::CONTEXTS.include?(context)

      raise ArgumentError, "Unknown insight context: #{context}. " \
        "Valid contexts: #{Insight::CONTEXTS.join(', ')}"
    end

    # Re-runs ExplanationBuilder to produce a final explanation that
    # incorporates the full set of suggestions, not just the first one.
    def enrich_explanation(result, suggestions)
      base_explanation = result[:explanation].to_s
      return base_explanation if suggestions.size <= 1

      summary = suggestions.map { |s| s.truncate(80) }.join("; ")
      "#{base_explanation} Suggestions cover: #{summary}."
    end

    def save_insight(suggestions, explanation)
      profile.insights.find_or_initialize_by(context: context).tap do |insight|
        insight.suggestions = suggestions
        insight.explanation = explanation
        insight.save!
      end
    end
  end
end

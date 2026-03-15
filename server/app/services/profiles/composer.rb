# frozen_string_literal: true

module Profiles
  # Takes an assessment with domain_scores and type classification, and
  # creates a Profile record. This is the primary entry point for building
  # a user-facing profile from scored assessment data.
  #
  # Steps:
  #   1. Looks up PersonalityType by type_code
  #   2. Builds score_vector from assessment domain_scores
  #   3. Pulls strengths and caution_patterns from PersonalityType
  #   4. Generates suggested_actions based on the type
  #   5. Applies ToneFilter to all text content before saving
  #
  # Usage:
  #   profile = Profiles::Composer.new(assessment, type_code: "ENFP").call
  #   # => #<Profile type_code: "ENFP", score_vector: {...}, ...>
  #
  class Composer
    attr_reader :assessment, :type_code

    def initialize(assessment, type_code:)
      @assessment = assessment
      @type_code = type_code.to_s.upcase
    end

    def call
      personality_type = find_personality_type!
      score_vector = build_score_vector
      strengths = filter_texts(personality_type.strengths || [])
      caution_patterns = filter_texts(personality_type.caution_patterns || [])
      suggested_actions = filter_texts(generate_suggested_actions(personality_type, score_vector))

      create_profile!(
        personality_type: personality_type,
        score_vector: score_vector,
        strengths: strengths,
        caution_patterns: caution_patterns,
        suggested_actions: suggested_actions,
      )
    end

    private

    def find_personality_type!
      personality_type = PersonalityType.find_by_code(type_code)

      unless personality_type
        raise ArgumentError, "Unknown personality type code: #{type_code}"
      end

      personality_type
    end

    # Builds a hash mapping each domain to its normalized score (0-100).
    # Example: { "energy" => 72, "decision_making" => 45, ... }
    def build_score_vector
      assessment.domain_scores.each_with_object({}) do |ds, vector|
        vector[ds.domain] = ds.normalized_score
      end
    end

    # Generates suggested actions based on the personality type's content
    # and the score vector. These are behavioral, action-oriented
    # recommendations that avoid labeling or deterministic claims.
    def generate_suggested_actions(personality_type, score_vector)
      actions = []

      # Type-specific suggestions from personality_type fields
      if personality_type.collaboration_style.present?
        actions << "In teamwork: #{personality_type.collaboration_style}"
      end

      if personality_type.conflict_style.present?
        actions << "When facing friction: #{personality_type.conflict_style}"
      end

      if personality_type.learning_style.present?
        actions << "For learning: #{personality_type.learning_style}"
      end

      if personality_type.recovery_style.present?
        actions << "For recovery: #{personality_type.recovery_style}"
      end

      if personality_type.career_hints.present?
        actions << "Career exploration: #{personality_type.career_hints}"
      end

      # Score-based suggestions for domains at the extremes
      score_vector.each do |domain, score|
        numeric_score = score.to_f
        if numeric_score >= 75
          actions << strong_domain_action(domain)
        elsif numeric_score <= 25
          actions << growth_domain_action(domain)
        end
      end

      actions.compact
    end

    def strong_domain_action(domain)
      case domain
      when "energy"
        "Your energy orientation is a notable strength. " \
          "Consider how you can channel it to support others around you."
      when "decision_making"
        "Your decision-making clarity is a strength. " \
          "Look for opportunities to guide team decisions while staying open to input."
      when "relationship"
        "Your people orientation is a strength. " \
          "Use it to build bridges, and remember to invest in your own needs too."
      when "recovery"
        "Your recovery resilience is a strength. " \
          "Model healthy rest practices even when you feel you could keep going."
      end
    end

    def growth_domain_action(domain)
      case domain
      when "energy"
        "You may benefit from experimenting with your energy boundaries — " \
          "try small adjustments to see what feels sustainable."
      when "decision_making"
        "You may benefit from building lightweight decision frameworks " \
          "for recurring choices to reduce decision fatigue."
      when "relationship"
        "You may benefit from identifying one or two relationships " \
          "to invest in more intentionally this month."
      when "recovery"
        "You may benefit from scheduling non-negotiable recovery blocks " \
          "in your calendar, even if they feel unnecessary at first."
      end
    end

    # Applies ToneFilter to an array of text strings.
    def filter_texts(texts)
      texts.map { |text| Profiles::ToneFilter.new(text).call }
    end

    def create_profile!(personality_type:, score_vector:, strengths:, caution_patterns:, suggested_actions:)
      ::Profile.create!(
        assessment: assessment,
        anonymous_session: assessment.anonymous_session,
        personality_type: personality_type,
        type_code: type_code,
        score_vector: score_vector,
        strengths: strengths,
        caution_patterns: caution_patterns,
        suggested_actions: suggested_actions,
      )
    end
  end
end

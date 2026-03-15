# frozen_string_literal: true

module Scoring
  # Calculates raw scores per domain from an assessment's responses.
  #
  # Each domain (energy, decision_making, relationship, recovery) has a set of
  # questions scored on a 1-5 Likert scale. Questions with negative polarity
  # are reverse-scored (6 - value) so that higher raw scores consistently
  # indicate one end of the spectrum across all items.
  #
  # Skipped responses (value: nil) are excluded from the sum. The returned
  # hash maps each domain to its raw score total.
  #
  # Usage:
  #   result = Scoring::DomainCalculator.new(assessment).call
  #   # => { "energy" => 18, "decision_making" => 12, ... }
  #
  class DomainCalculator
    DOMAINS = Question::DOMAINS

    attr_reader :assessment

    def initialize(assessment)
      @assessment = assessment
    end

    def call
      DOMAINS.each_with_object({}) do |domain, scores|
        scores[domain] = raw_score_for(domain)
      end
    end

    private

    def raw_score_for(domain)
      domain_responses(domain).sum do |response|
        effective_value(response)
      end
    end

    def domain_responses(domain)
      responses_with_questions.select do |response|
        response.question.domain == domain && !response.skipped?
      end
    end

    def effective_value(response)
      value = response.value
      return 0 if value.nil?

      response.question.negative? ? (6 - value) : value
    end

    # Eager-load questions once to avoid N+1 queries across all domains.
    def responses_with_questions
      @responses_with_questions ||= assessment.responses.includes(:question).to_a
    end
  end
end

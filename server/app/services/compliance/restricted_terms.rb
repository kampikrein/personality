# frozen_string_literal: true

module Compliance
  # Maintains the canonical list of trademarked and restricted terms that must
  # not appear in user-facing content. Provides scanning utilities used by
  # other compliance services to detect violations.
  #
  # Two categories exist:
  #   RESTRICTED        - terms that are never allowed in regular content.
  #   ALLOWED_IN_TRUST_NOTICE - a subset of RESTRICTED that may appear inside
  #                             the legally-required trust notice (e.g. "This
  #                             service is not affiliated with MBTI...").
  #
  # Usage:
  #   violations = Compliance::RestrictedTerms.scan("Your MBTI type is...")
  #   # => ["MBTI"]
  #
  #   Compliance::RestrictedTerms.clean?("Safe text here")
  #   # => true
  #
  class RestrictedTerms
    RESTRICTED = [
      # Trademarked assessment names
      "MBTI", "Myers-Briggs", "마이어스-브릭스", "Myers-Briggs Type Indicator",
      "에니어그램", "Enneagram",
      # Official MBTI type names (Korean 16Personalities names)
      "옹호자", "중재자", "선의의 옹호자", "정의의 사도",
      "논리학자", "건축가", "과학자", "전략가",
      "활동가", "재기발랄한 활동가", "호기심 많은 예술가", "모험을 즐기는 사업가",
      "사업가", "경영자", "수호자", "현실주의자",
      "용감한 수호자", "열정적인 중재자",
      # English MBTI official names
      "The Inspector", "The Protector", "The Counselor", "The Mastermind",
      "The Crafter", "The Composer", "The Healer", "The Architect",
      "The Dynamo", "The Performer", "The Champion", "The Visionary",
      "The Supervisor", "The Provider", "The Teacher", "The Commander"
    ].freeze

    ALLOWED_IN_TRUST_NOTICE = ["MBTI", "Myers-Briggs"].freeze

    # Scans +text+ and returns an array of restricted terms found.
    # The search is case-insensitive to catch variations like "mbti" or "Mbti".
    #
    # @param text [String]
    # @return [Array<String>] list of matched restricted terms
    def self.scan(text)
      return [] if text.nil? || text.empty?

      RESTRICTED.select { |term| text.match?(/#{Regexp.escape(term)}/i) }
    end

    # Returns +true+ when the text contains no restricted terms.
    #
    # When +allow_trust_notice+ is true, terms listed in ALLOWED_IN_TRUST_NOTICE
    # are exempt so that the legally-required disclaimer can reference them.
    #
    # @param text [String]
    # @param allow_trust_notice [Boolean]
    # @return [Boolean]
    def self.clean?(text, allow_trust_notice: false)
      violations = scan(text)

      if allow_trust_notice
        violations -= ALLOWED_IN_TRUST_NOTICE
      end

      violations.empty?
    end
  end
end

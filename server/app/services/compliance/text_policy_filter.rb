# frozen_string_literal: true

module Compliance
  # Filters all user-facing text through the restricted-terms policy before
  # it is displayed. Every piece of text that leaves the system must pass
  # through this filter.
  #
  # Two contexts are supported:
  #   :trust_notice - The legally-mandated disclaimer ("This service is not
  #                   affiliated with MBTI..."). References to MBTI and
  #                   Myers-Briggs are permitted here.
  #   :content      - All other user-facing text (profiles, insights, UI
  #                   copy). Every restricted term is blocked.
  #
  # Usage:
  #   result = Compliance::TextPolicyFilter.new("Your MBTI type is INFP", :content).call
  #   # => { clean: false, violations: ["MBTI"], filtered_text: "Your [REMOVED] type is INFP" }
  #
  class TextPolicyFilter
    CONTEXTS = %i[trust_notice content].freeze
    REPLACEMENT = "[REMOVED]"

    attr_reader :text, :context

    # @param text [String] the text to filter
    # @param context [Symbol] :trust_notice or :content
    def initialize(text, context = :content)
      @text = text.to_s
      @context = context

      unless CONTEXTS.include?(@context)
        raise ArgumentError, "Unknown context #{@context.inspect}. Must be one of: #{CONTEXTS.join(', ')}"
      end
    end

    # @return [Hash] { clean: Boolean, violations: Array<String>, filtered_text: String }
    def call
      violations = detect_violations
      filtered = redact(violations)

      {
        clean: violations.empty?,
        violations: violations,
        filtered_text: filtered
      }
    end

    private

    def detect_violations
      all_violations = RestrictedTerms.scan(text)

      if context == :trust_notice
        all_violations - RestrictedTerms::ALLOWED_IN_TRUST_NOTICE
      else
        all_violations
      end
    end

    def redact(violations)
      return text if violations.empty?

      result = text.dup
      violations.each do |term|
        result.gsub!(/#{Regexp.escape(term)}/i, REPLACEMENT)
      end
      result
    end
  end
end

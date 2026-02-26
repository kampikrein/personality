# frozen_string_literal: true

module Profiles
  # Filters text for stigmatizing or deterministic language.
  #
  # The design document requires that all user-facing content avoids
  # fixed-identity labeling, absolute claims, and comparative judgments.
  # This filter scans text and replaces problematic patterns with
  # growth-oriented, non-deterministic alternatives.
  #
  # Usage:
  #   filtered = Profiles::ToneFilter.new(text).call
  #   # => text with stigmatizing language replaced
  #
  class ToneFilter
    # Ordered list of replacement rules. Each entry is a pair:
    #   [pattern, replacement]
    # Patterns are applied sequentially, so earlier replacements may
    # affect later matches.
    RULES = [
      # "you are [type]" -> "you tend toward [type]"
      [/\byou are\b/i, "you tend toward"],

      # Absolute qualifiers
      [/\balways\b/i, "often"],
      [/\bnever\b/i, "rarely"],

      # Inability framing -> challenge framing
      [/\bcan'?t\b/i, "may find challenging"],
      [/\bcannot\b/i, "may find challenging"],
      [/\bunable to\b/i, "may find it challenging to"],

      # Comparative judgments (remove entirely)
      [/\bbetter than\b/i, ""],
      [/\bworse than\b/i, ""],
      [/\bsuperior to\b/i, ""],
      [/\binferior to\b/i, ""],
    ].freeze

    attr_reader :text

    def initialize(text)
      @text = text.to_s.dup
    end

    def call
      return text if text.blank?

      filtered = RULES.reduce(text) do |result, (pattern, replacement)|
        result.gsub(pattern) { match_case($&, replacement) }
      end

      # Collapse any double spaces left by removals
      filtered.gsub(/  +/, " ").strip
    end

    private

    # Preserves the leading case of the original match in the replacement.
    # If the match started with an uppercase letter and the replacement is
    # non-empty, capitalize the replacement's first character.
    def match_case(original, replacement)
      return replacement if replacement.empty? || original.empty?

      if original[0] == original[0].upcase
        replacement[0].upcase + replacement[1..]
      else
        replacement
      end
    end
  end
end

# frozen_string_literal: true

module Profiles
  # Maps a type_code to personality_types content in the requested locale.
  #
  # Provides character_name, summary, strengths, and caution_patterns
  # for a given personality type. Locale defaults to :ko (Korean) and
  # falls back to :en if the requested locale column is blank.
  #
  # Usage:
  #   content = Profiles::TypeContentService.new("ENFP", locale: :ko).call
  #   # => { character_name: "...", summary: "...", strengths: [...], caution_patterns: [...] }
  #
  class TypeContentService
    SUPPORTED_LOCALES = %i[ko en].freeze

    attr_reader :type_code, :locale

    def initialize(type_code, locale: :ko)
      @type_code = type_code.to_s.upcase
      @locale = SUPPORTED_LOCALES.include?(locale.to_sym) ? locale.to_sym : :ko
    end

    def call
      personality_type = PersonalityType.find_by_code(type_code)

      raise ArgumentError, "Unknown personality type: #{type_code}" unless personality_type

      {
        character_name: localized_field(personality_type, :character_name),
        summary: localized_field(personality_type, :summary),
        strengths: personality_type.strengths || [],
        caution_patterns: personality_type.caution_patterns || [],
      }
    end

    private

    # Returns the locale-specific field, falling back to the other locale
    # if the primary one is blank.
    def localized_field(record, field_base)
      primary = record.public_send(:"#{field_base}_#{locale}")
      return primary if primary.present?

      fallback_locale = (locale == :ko) ? :en : :ko
      record.public_send(:"#{field_base}_#{fallback_locale}")
    end
  end
end

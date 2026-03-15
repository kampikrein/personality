# frozen_string_literal: true

module Quality
  # Detects bot-like response patterns in a completed assessment. Three
  # heuristics are evaluated independently; the final confidence score is
  # the proportion of heuristics that fired.
  #
  # Patterns detected:
  #   :uniform       - Every response has the same value (e.g. all 3s).
  #   :sequential    - Responses follow a perfect repeating sequence
  #                    (e.g. 1,2,3,4,5,1,2,3,4,5...).
  #   :zero_variance_timing - All response_time_ms values are identical,
  #                           suggesting automated submission.
  #
  # Usage:
  #   result = Quality::BotDetector.new(assessment).call
  #   # => { bot_suspected: true, patterns: [:uniform], confidence: 0.33 }
  #
  class BotDetector
    HEURISTICS = %i[uniform sequential zero_variance_timing].freeze

    attr_reader :assessment

    def initialize(assessment)
      @assessment = assessment
    end

    # @return [Hash] { bot_suspected: Boolean, patterns: Array<Symbol>, confidence: Float }
    def call
      responses = assessment.responses.answered.order(:sequence_number).to_a
      return no_data_result if responses.size < 2

      patterns = []
      patterns << :uniform              if uniform?(responses)
      patterns << :sequential           if sequential?(responses)
      patterns << :zero_variance_timing if zero_variance_timing?(responses)

      confidence = patterns.size.to_f / HEURISTICS.size

      {
        bot_suspected: patterns.any?,
        patterns: patterns,
        confidence: confidence.round(2)
      }
    end

    private

    # All answered responses share exactly the same value.
    def uniform?(responses)
      values = responses.map(&:value)
      values.uniq.size == 1
    end

    # Values follow a perfectly repeating cycle. We test every plausible
    # cycle length from 2 up to 5 (the Likert scale width).
    def sequential?(responses)
      values = responses.map(&:value)
      return false if values.size < 2

      (2..5).any? do |cycle_length|
        cycle = values.first(cycle_length)
        expected = Array.new(values.size) { |i| cycle[i % cycle_length] }
        values == expected && cycle.uniq.size > 1
      end
    end

    # Every response was submitted with exactly the same timing, indicating
    # automated rather than human input. Nil timings are excluded; if fewer
    # than 2 timings remain, the heuristic does not fire.
    def zero_variance_timing?(responses)
      timings = responses.filter_map(&:response_time_ms)
      return false if timings.size < 2

      timings.uniq.size == 1
    end

    def no_data_result
      { bot_suspected: false, patterns: [], confidence: 0.0 }
    end
  end
end

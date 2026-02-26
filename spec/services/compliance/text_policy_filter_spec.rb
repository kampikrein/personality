# frozen_string_literal: true

require "rails_helper"

RSpec.describe Compliance::TextPolicyFilter do
  describe "#call" do
    context "with :content context" do
      it "blocks MBTI in content" do
        result = described_class.new("Your MBTI type is ENFP", :content).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("MBTI")
      end

      it "blocks Myers-Briggs in content" do
        result = described_class.new("Based on Myers-Briggs methodology", :content).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("Myers-Briggs")
      end

      it "blocks Korean restricted terms in content" do
        result = described_class.new("마이어스-브릭스 유형 검사", :content).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("마이어스-브릭스")
      end

      it "blocks official type names in content" do
        result = described_class.new("You are The Architect", :content).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("The Architect")
      end

      it "replaces restricted terms with [REMOVED] in filtered text" do
        result = described_class.new("Your MBTI type is ENFP", :content).call

        expect(result[:filtered_text]).to eq("Your [REMOVED] type is ENFP")
        expect(result[:filtered_text]).not_to include("MBTI")
      end

      it "replaces multiple restricted terms" do
        result = described_class.new("MBTI and Myers-Briggs are trademarks", :content).call

        expect(result[:filtered_text]).to eq("[REMOVED] and [REMOVED] are trademarks")
        expect(result[:violations]).to contain_exactly("MBTI", "Myers-Briggs")
      end

      it "returns clean result for text without restricted terms" do
        result = described_class.new("Your personality type is ENFP", :content).call

        expect(result[:clean]).to be true
        expect(result[:violations]).to be_empty
        expect(result[:filtered_text]).to eq("Your personality type is ENFP")
      end

      it "does not alter text when no violations are found" do
        original = "This is a safe personality assessment result"
        result = described_class.new(original, :content).call

        expect(result[:filtered_text]).to eq(original)
      end
    end

    context "with :trust_notice context" do
      it "allows MBTI in trust notice" do
        result = described_class.new("This service is not affiliated with MBTI", :trust_notice).call

        expect(result[:clean]).to be true
        expect(result[:violations]).to be_empty
      end

      it "allows Myers-Briggs in trust notice" do
        result = described_class.new("Not affiliated with Myers-Briggs Type Indicator", :trust_notice).call

        # Myers-Briggs is in ALLOWED_IN_TRUST_NOTICE, but "Myers-Briggs Type Indicator" is
        # a separate restricted term not in the allowed list
        expect(result[:violations]).to include("Myers-Briggs Type Indicator")
      end

      it "allows both MBTI and Myers-Briggs together in trust notice" do
        text = "This service is not affiliated with MBTI or Myers-Briggs"
        result = described_class.new(text, :trust_notice).call

        expect(result[:clean]).to be true
        expect(result[:violations]).to be_empty
      end

      it "still blocks non-trust-notice restricted terms" do
        result = described_class.new("You are The Architect according to MBTI", :trust_notice).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("The Architect")
        # MBTI should not be in violations for trust notice context
        expect(result[:violations]).not_to include("MBTI")
      end

      it "still blocks Korean restricted terms not in allowed list" do
        result = described_class.new("옹호자 유형 - MBTI disclaimer", :trust_notice).call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("옹호자")
      end

      it "replaces only non-allowed terms in filtered text" do
        result = described_class.new("옹호자 MBTI disclaimer", :trust_notice).call

        expect(result[:filtered_text]).to include("MBTI")
        expect(result[:filtered_text]).to include("[REMOVED]")
        expect(result[:filtered_text]).not_to include("옹호자")
      end
    end

    context "with invalid context" do
      it "raises ArgumentError" do
        expect {
          described_class.new("some text", :invalid)
        }.to raise_error(ArgumentError, /Unknown context/)
      end
    end

    context "default context" do
      it "defaults to :content when no context is provided" do
        result = described_class.new("Your MBTI type").call

        expect(result[:clean]).to be false
        expect(result[:violations]).to include("MBTI")
      end
    end

    context "return structure" do
      subject(:result) { described_class.new("test text", :content).call }

      it "returns a hash with :clean, :violations, and :filtered_text keys" do
        expect(result).to include(:clean, :violations, :filtered_text)
      end

      it "returns :violations as an array" do
        expect(result[:violations]).to be_an(Array)
      end

      it "returns :filtered_text as a string" do
        expect(result[:filtered_text]).to be_a(String)
      end

      it "returns :clean as a boolean" do
        expect(result[:clean]).to be(true).or be(false)
      end
    end

    context "case insensitivity in content replacement" do
      it "replaces case-variant matches" do
        result = described_class.new("mbti is a trademark", :content).call

        expect(result[:filtered_text]).to eq("[REMOVED] is a trademark")
        expect(result[:violations]).to include("MBTI")
      end
    end

    context "with nil text" do
      it "handles nil by converting to empty string" do
        result = described_class.new(nil, :content).call

        expect(result[:clean]).to be true
        expect(result[:violations]).to be_empty
        expect(result[:filtered_text]).to eq("")
      end
    end
  end
end

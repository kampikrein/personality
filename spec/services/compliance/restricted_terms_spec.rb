# frozen_string_literal: true

require "rails_helper"

RSpec.describe Compliance::RestrictedTerms do
  describe ".scan" do
    it "detects 'MBTI' in text" do
      violations = described_class.scan("Your MBTI result is ready")
      expect(violations).to include("MBTI")
    end

    it "detects 'MBTI' case-insensitively" do
      violations = described_class.scan("your mbti result is ready")
      expect(violations).to include("MBTI")
    end

    it "detects 'Myers-Briggs' in text" do
      violations = described_class.scan("Based on Myers-Briggs methodology")
      expect(violations).to include("Myers-Briggs")
    end

    it "detects 'Myers-Briggs' case-insensitively" do
      violations = described_class.scan("based on myers-briggs methodology")
      expect(violations).to include("Myers-Briggs")
    end

    it "detects Korean term '마이어스-브릭스'" do
      violations = described_class.scan("마이어스-브릭스 유형 검사")
      expect(violations).to include("마이어스-브릭스")
    end

    it "detects Korean term '옹호자'" do
      violations = described_class.scan("당신은 옹호자 유형입니다")
      expect(violations).to include("옹호자")
    end

    it "detects '에니어그램'" do
      violations = described_class.scan("에니어그램 검사를 진행합니다")
      expect(violations).to include("에니어그램")
    end

    it "detects 'Enneagram'" do
      violations = described_class.scan("This is an Enneagram assessment")
      expect(violations).to include("Enneagram")
    end

    it "does NOT flag 4-letter personality type codes like ENFP" do
      violations = described_class.scan("Your type is ENFP")
      expect(violations).to be_empty
    end

    it "does NOT flag 4-letter personality type codes like INTP" do
      violations = described_class.scan("INTP personality profile")
      expect(violations).to be_empty
    end

    it "does NOT flag 4-letter personality type codes like ISTJ" do
      violations = described_class.scan("ISTJ results are ready")
      expect(violations).to be_empty
    end

    it "returns an empty array for clean text" do
      violations = described_class.scan("Your personality assessment is complete")
      expect(violations).to be_empty
    end

    it "returns an empty array for nil input" do
      violations = described_class.scan(nil)
      expect(violations).to be_empty
    end

    it "returns an empty array for empty string" do
      violations = described_class.scan("")
      expect(violations).to be_empty
    end

    it "detects multiple restricted terms in the same text" do
      violations = described_class.scan("MBTI and Myers-Briggs are trademarks")
      expect(violations).to include("MBTI", "Myers-Briggs")
    end

    it "detects English official type names" do
      violations = described_class.scan("You are The Architect of your own life")
      expect(violations).to include("The Architect")
    end

    it "detects Korean official type names like '논리학자'" do
      violations = described_class.scan("논리학자 유형의 특성")
      expect(violations).to include("논리학자")
    end
  end

  describe ".clean?" do
    it "returns true for text with no restricted terms" do
      expect(described_class.clean?("Your personality profile is ready")).to be true
    end

    it "returns false for text containing MBTI" do
      expect(described_class.clean?("Your MBTI type is ENFP")).to be false
    end

    it "returns false for text containing Myers-Briggs" do
      expect(described_class.clean?("Based on Myers-Briggs")).to be false
    end

    it "returns false for text containing Korean restricted terms" do
      expect(described_class.clean?("마이어스-브릭스 유형")).to be false
    end

    context "with allow_trust_notice: true" do
      it "allows 'MBTI' in text" do
        expect(described_class.clean?("This is not affiliated with MBTI", allow_trust_notice: true)).to be true
      end

      it "allows 'Myers-Briggs' in text" do
        expect(described_class.clean?("Not affiliated with Myers-Briggs", allow_trust_notice: true)).to be true
      end

      it "still flags non-trust-notice restricted terms" do
        expect(described_class.clean?("You are The Architect type", allow_trust_notice: true)).to be false
      end

      it "still flags Korean restricted terms not in ALLOWED_IN_TRUST_NOTICE" do
        expect(described_class.clean?("마이어스-브릭스 유형", allow_trust_notice: true)).to be false
      end

      it "allows text with only MBTI and Myers-Briggs" do
        text = "This service is not affiliated with MBTI or Myers-Briggs"
        expect(described_class.clean?(text, allow_trust_notice: true)).to be true
      end
    end

    context "with allow_trust_notice: false (default)" do
      it "flags MBTI" do
        expect(described_class.clean?("Not affiliated with MBTI")).to be false
      end

      it "flags Myers-Briggs" do
        expect(described_class.clean?("Not affiliated with Myers-Briggs")).to be false
      end
    end
  end
end

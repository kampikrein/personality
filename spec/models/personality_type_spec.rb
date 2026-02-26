require "rails_helper"

RSpec.describe PersonalityType, type: :model do
  # Clean up any seeded data to avoid uniqueness conflicts
  before { PersonalityType.delete_all }

  describe "VALID_CODES" do
    it "contains exactly 16 codes" do
      expect(PersonalityType::VALID_CODES.size).to eq(16)
    end

    it "includes all 16 personality type codes" do
      expected = %w[
        ENFP ENFJ ENTP ENTJ
        ESFP ESFJ ESTP ESTJ
        INFP INFJ INTP INTJ
        ISFP ISFJ ISTP ISTJ
      ]

      expect(PersonalityType::VALID_CODES).to match_array(expected)
    end
  end

  describe "validations" do
    it "accepts all 16 valid codes" do
      PersonalityType::VALID_CODES.each do |code|
        pt = build(:personality_type, code: code,
                   character_name_ko: "이름 #{code}",
                   character_name_en: "Name #{code}")
        expect(pt).to be_valid, "expected code '#{code}' to be valid, got errors: #{pt.errors.full_messages}"
      end
    end

    it "rejects invalid codes" do
      %w[XXXX ABCD enfp Enfp EN ENFPP].each do |code|
        pt = build(:personality_type, code: code)
        expect(pt).not_to be_valid, "expected code '#{code}' to be invalid"
      end
    end

    it "requires a code" do
      pt = build(:personality_type, code: nil)
      expect(pt).not_to be_valid
      expect(pt.errors[:code]).to include("can't be blank")
    end

    it "requires character_name_ko" do
      pt = build(:personality_type, character_name_ko: nil)
      expect(pt).not_to be_valid
      expect(pt.errors[:character_name_ko]).to include("can't be blank")
    end

    it "requires character_name_en" do
      pt = build(:personality_type, character_name_en: nil)
      expect(pt).not_to be_valid
      expect(pt.errors[:character_name_en]).to include("can't be blank")
    end

    it "enforces uniqueness of code" do
      create(:personality_type, code: "ENFP")
      duplicate = build(:personality_type, code: "ENFP")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to include("has already been taken")
    end
  end

  describe ".find_by_code" do
    before do
      create(:personality_type, code: "INTJ",
             character_name_ko: "먼 곳을 보는 눈",
             character_name_en: "Far-Seeing Eye")
    end

    it "finds a personality type by exact uppercase code" do
      result = PersonalityType.find_by_code("INTJ")
      expect(result).to be_present
      expect(result.code).to eq("INTJ")
    end

    it "finds a personality type case-insensitively (lowercase)" do
      result = PersonalityType.find_by_code("intj")
      expect(result).to be_present
      expect(result.code).to eq("INTJ")
    end

    it "finds a personality type case-insensitively (mixed case)" do
      result = PersonalityType.find_by_code("InTj")
      expect(result).to be_present
      expect(result.code).to eq("INTJ")
    end

    it "returns nil for a non-existent code" do
      result = PersonalityType.find_by_code("XXXX")
      expect(result).to be_nil
    end
  end

  describe "associations" do
    it "has many profiles" do
      pt = create(:personality_type, code: "ISFP",
                  character_name_ko: "감각의 예술가",
                  character_name_en: "Sensory Artist")
      expect(pt).to respond_to(:profiles)
    end
  end
end

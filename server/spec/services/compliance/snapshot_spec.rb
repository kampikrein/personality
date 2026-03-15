require "rails_helper"

RSpec.describe "Compliance::Snapshot — Legal Content Verification", type: :model do
  # Seed the database once for all tests in this file.
  # We use before(:all) to load seed data only once, improving performance.
  # Note: before(:all) runs outside the transactional wrapper, so we clean up
  # at the end if needed, but for read-only snapshot tests this is safe.
  before(:all) do
    Rails.application.load_seed
  end

  let(:all_personality_types) { PersonalityType.all }
  let(:restricted_terms) { Compliance::RestrictedTerms::RESTRICTED }

  describe "seed data completeness" do
    it "has all 16 personality types loaded" do
      expect(all_personality_types.count).to eq(16)
    end

    it "has one PersonalityType for each VALID_CODE" do
      PersonalityType::VALID_CODES.each do |code|
        expect(PersonalityType.find_by(code: code)).to be_present,
          "Missing PersonalityType for code: #{code}"
      end
    end
  end

  describe "character_name_ko restricted term scan" do
    it "contains 0 restricted term violations across all 16 types" do
      violations = []

      all_personality_types.each do |pt|
        found = Compliance::RestrictedTerms.scan(pt.character_name_ko)
        if found.any?
          violations << { code: pt.code, field: "character_name_ko",
                          value: pt.character_name_ko, terms: found }
        end
      end

      expect(violations).to eq([]),
        "Restricted terms found in character_name_ko:\n" \
        "#{violations.map { |v| "  #{v[:code]}: '#{v[:value]}' contains #{v[:terms]}" }.join("\n")}"
    end
  end

  describe "summary_ko restricted term scan" do
    it "contains 0 restricted term violations across all 16 types" do
      violations = []

      all_personality_types.each do |pt|
        found = Compliance::RestrictedTerms.scan(pt.summary_ko)
        if found.any?
          violations << { code: pt.code, field: "summary_ko",
                          value: pt.summary_ko.truncate(80), terms: found }
        end
      end

      expect(violations).to eq([]),
        "Restricted terms found in summary_ko:\n" \
        "#{violations.map { |v| "  #{v[:code]}: '#{v[:value]}' contains #{v[:terms]}" }.join("\n")}"
    end
  end

  describe "view templates restricted term scan" do
    let(:template_dir) { Rails.root.join("app/views") }
    let(:trust_notice_path) { Rails.root.join("app/views/results/_trust_notice.html.erb") }

    it "contains 0 restricted term violations in all ERB templates (excluding trust_notice)" do
      violations = []

      Dir.glob(template_dir.join("**/*.erb")).each do |file_path|
        # Skip the trust notice partial — it is legally required to mention MBTI
        next if File.expand_path(file_path) == File.expand_path(trust_notice_path)

        content = File.read(file_path)
        found = Compliance::RestrictedTerms.scan(content)

        if found.any?
          relative = Pathname.new(file_path).relative_path_from(Rails.root)
          violations << { file: relative.to_s, terms: found }
        end
      end

      expect(violations).to eq([]),
        "Restricted terms found in view templates:\n" \
        "#{violations.map { |v| "  #{v[:file]}: #{v[:terms]}" }.join("\n")}"
    end
  end

  describe "Trust Notice partial" do
    let(:trust_notice_path) { Rails.root.join("app/views/results/_trust_notice.html.erb") }

    it "exists at the expected path" do
      expect(File.exist?(trust_notice_path)).to be(true),
        "Trust Notice partial not found at: #{trust_notice_path}"
    end

    it "contains the required disclaimer that the service is not affiliated with official MBTI" do
      content = File.read(trust_notice_path)

      # Korean disclaimer: "공식 MBTI 검사와 무관" (not affiliated with official MBTI)
      expect(content).to include("공식 MBTI"),
        "Trust Notice must reference '공식 MBTI' (official MBTI) in the disclaimer"
    end

    it "contains the disclaimer that results are not psychological diagnosis" do
      content = File.read(trust_notice_path)

      # Korean: "심리학적 진단이 아닙니다" (not a psychological diagnosis)
      expect(content).to include("심리학적 진단이 아닙니다"),
        "Trust Notice must state results are not a psychological diagnosis"
    end

    it "mentions Myers-Briggs Company" do
      content = File.read(trust_notice_path)

      expect(content).to include("Myers-Briggs Company"),
        "Trust Notice must mention The Myers-Briggs Company for legal clarity"
    end
  end

  describe "character name originality" do
    # Official MBTI type names that our characters must NOT match.
    # These are the well-known English names from The Myers-Briggs Company and
    # popular Korean translations from 16Personalities.
    let(:official_mbti_names_en) do
      [
        "The Inspector", "The Protector", "The Counselor", "The Mastermind",
        "The Crafter", "The Composer", "The Healer", "The Architect",
        "The Dynamo", "The Performer", "The Champion", "The Visionary",
        "The Supervisor", "The Provider", "The Teacher", "The Commander"
      ]
    end

    let(:official_mbti_names_ko) do
      [
        "옹호자", "중재자", "선의의 옹호자", "정의의 사도",
        "논리학자", "건축가", "과학자", "전략가",
        "활동가", "재기발랄한 활동가", "호기심 많은 예술가", "모험을 즐기는 사업가",
        "사업가", "경영자", "수호자", "현실주의자",
        "용감한 수호자", "열정적인 중재자"
      ]
    end

    it "has 16 unique character_name_ko values (no duplicates)" do
      names = all_personality_types.pluck(:character_name_ko)
      expect(names.uniq.size).to eq(16),
        "Expected 16 unique Korean character names, got #{names.uniq.size}. Duplicates: #{names.group_by(&:itself).select { |_, v| v.size > 1 }.keys}"
    end

    it "has 16 unique character_name_en values (no duplicates)" do
      names = all_personality_types.pluck(:character_name_en)
      expect(names.uniq.size).to eq(16),
        "Expected 16 unique English character names, got #{names.uniq.size}. Duplicates: #{names.group_by(&:itself).select { |_, v| v.size > 1 }.keys}"
    end

    it "has no character_name_en that matches an official MBTI English name" do
      violations = []

      all_personality_types.each do |pt|
        official_mbti_names_en.each do |official_name|
          if pt.character_name_en.downcase == official_name.downcase
            violations << { code: pt.code, our_name: pt.character_name_en, official_name: official_name }
          end
        end
      end

      expect(violations).to eq([]),
        "Character names must differ from official MBTI names:\n" \
        "#{violations.map { |v| "  #{v[:code]}: '#{v[:our_name]}' matches official '#{v[:official_name]}'" }.join("\n")}"
    end

    it "has no character_name_ko that matches an official MBTI Korean name" do
      violations = []

      all_personality_types.each do |pt|
        official_mbti_names_ko.each do |official_name|
          if pt.character_name_ko == official_name
            violations << { code: pt.code, our_name: pt.character_name_ko, official_name: official_name }
          end
        end
      end

      expect(violations).to eq([]),
        "Korean character names must differ from official MBTI Korean names:\n" \
        "#{violations.map { |v| "  #{v[:code]}: '#{v[:our_name]}' matches official '#{v[:official_name]}'" }.join("\n")}"
    end
  end

  describe "full content restricted term scan (all text fields)" do
    it "finds 0 violations across all text fields of all personality types" do
      text_fields = %i[
        character_name_ko character_name_en
        summary_ko summary_en
        collaboration_style conflict_style
        learning_style career_hints recovery_style
      ]

      violations = []

      all_personality_types.each do |pt|
        text_fields.each do |field|
          value = pt.send(field)
          next if value.blank?

          found = Compliance::RestrictedTerms.scan(value)
          if found.any?
            violations << { code: pt.code, field: field,
                            value: value.truncate(60), terms: found }
          end
        end

        # Also check array fields
        (pt.strengths || []).each_with_index do |s, i|
          found = Compliance::RestrictedTerms.scan(s)
          if found.any?
            violations << { code: pt.code, field: "strengths[#{i}]",
                            value: s, terms: found }
          end
        end

        (pt.caution_patterns || []).each_with_index do |c, i|
          found = Compliance::RestrictedTerms.scan(c)
          if found.any?
            violations << { code: pt.code, field: "caution_patterns[#{i}]",
                            value: c, terms: found }
          end
        end
      end

      expect(violations).to eq([]),
        "Restricted terms found in personality type content:\n" \
        "#{violations.map { |v| "  #{v[:code]}.#{v[:field]}: '#{v[:value]}' contains #{v[:terms]}" }.join("\n")}"
    end
  end
end

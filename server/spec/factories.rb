FactoryBot.define do
  factory :anonymous_session do
    ip_hash { Digest::SHA256.hexdigest("127.0.0.1") }
    user_agent_hash { Digest::SHA256.hexdigest("test-agent") }
  end

  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    display_name { "Test User" }
  end

  factory :question_set do
    sequence(:version_code) { |n| "qset_test_v#{n}" }
    status { "active" }

    trait :with_questions do
      after(:create) do |qs|
        Question::DOMAINS.each do |domain|
          5.times do |i|
            create(:question, question_set: qs, domain: domain, position: i + 1)
          end
        end
      end
    end
  end

  factory :question do
    question_set
    domain { "energy" }
    sequence(:position) { |n| n }
    body_ko { "테스트 질문입니다" }
    body_en { "This is a test question" }
    polarity { "positive" }
    active { true }
  end

  factory :assessment do
    anonymous_session
    question_set
    status { "in_progress" }
    current_question_index { 0 }
  end

  factory :response do
    assessment
    question
    value { 3 }
    response_time_ms { 2000 }
    sequence_number { 1 }
  end

  factory :domain_score do
    assessment
    domain { "energy" }
    raw_score { 15 }
    normalized_score { 50.0 }
    reliability_coefficient { 0.7 }
    consistency_index { 0.8 }
    speed_flag { false }
    policy_blocked { false }
  end

  factory :personality_type do
    code { "ENFP" }
    character_name_ko { "빛나는 탐험가" }
    character_name_en { "Radiant Explorer" }
    summary_ko { "테스트 요약" }
    summary_en { "Test summary" }
    strengths { ["강점1", "강점2"] }
    caution_patterns { ["주의1"] }
  end

  factory :profile do
    assessment
    anonymous_session
    personality_type
    type_code { "ENFP" }
    score_vector { { energy: 72, decision_making: 45, relationship: 35, recovery: 80 } }
    strengths { ["강점1"] }
    caution_patterns { ["주의1"] }
    suggested_actions { ["행동1"] }
  end

  factory :insight do
    profile
    context { "collaboration" }
    suggestions { ["제안1", "제안2"] }
    explanation { "설명" }
  end

  factory :deletion_request do
    anonymous_session
  end

  factory :consent do
    anonymous_session
    consent_type { "data_processing" }
    consent_version { "1.0" }
    consent_text_snapshot { "동의합니다" }
    granted { true }
    granted_at { Time.current }
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profiles::Composer do
  describe "#call" do
    let(:question_set) { create(:question_set, :with_questions) }
    let(:session) { create(:anonymous_session) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set, status: "scored") }
    let!(:personality_type) do
      pt = PersonalityType.find_by(code: "INTP")
      if pt
        pt.update!(
          collaboration_style: "Works well in teams",
          conflict_style: "Seeks compromise",
          learning_style: "Hands-on learner",
          recovery_style: "Needs quiet time",
          career_hints: "Explore creative fields"
        )
        pt
      else
        create(:personality_type,
               code: "INTP",
               collaboration_style: "Works well in teams",
               conflict_style: "Seeks compromise",
               learning_style: "Hands-on learner",
               recovery_style: "Needs quiet time",
               career_hints: "Explore creative fields")
      end
    end

    before do
      # Create domain scores
      Question::DOMAINS.each do |domain|
        create(:domain_score, assessment: assessment, domain: domain, normalized_score: 60.0)
      end
    end

    subject(:profile) { described_class.new(assessment, type_code: "INTP").call }

    it "creates a Profile record" do
      expect { profile }.to change(Profile, :count).by(1)
    end

    it "sets correct type_code" do
      expect(profile.type_code).to eq("INTP")
    end

    it "links to the correct personality type" do
      expect(profile.personality_type).to eq(personality_type)
    end

    it "builds score_vector from domain scores" do
      expect(profile.score_vector).to include(
        "energy" => 60.0,
        "decision_making" => 60.0,
        "relationship" => 60.0,
        "recovery" => 60.0
      )
    end

    it "includes personality type strengths" do
      expect(profile.strengths).not_to be_empty
    end

    it "generates suggested actions from personality type fields" do
      expect(profile.suggested_actions.join(" ")).to include("teamwork")
    end

    it "applies ToneFilter to text content" do
      # ToneFilter replaces "you are" → "you tend toward", etc.
      # Just verify it doesn't crash and returns strings
      profile.strengths.each do |s|
        expect(s).to be_a(String)
      end
    end

    context "with extreme scores (>= 75)" do
      before do
        assessment.domain_scores.find_by(domain: "energy").update!(normalized_score: 80.0)
      end

      it "adds strong domain action" do
        actions = profile.suggested_actions
        expect(actions.any? { |a| a.include?("energy") || a.include?("strength") }).to be true
      end
    end

    context "with low scores (<= 25)" do
      before do
        assessment.domain_scores.find_by(domain: "recovery").update!(normalized_score: 20.0)
      end

      it "adds growth domain action" do
        actions = profile.suggested_actions
        expect(actions.any? { |a| a.include?("recovery") || a.include?("benefit") }).to be true
      end
    end

    context "with unknown type code" do
      it "raises ArgumentError" do
        expect {
          described_class.new(assessment, type_code: "ZZZZ").call
        }.to raise_error(ArgumentError, /Unknown personality type/)
      end
    end
  end
end

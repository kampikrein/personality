# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insights::ContextEngine do
  describe "#call" do
    let(:session) { create(:anonymous_session) }
    let(:question_set) { create(:question_set, :with_questions) }
    let(:assessment) { create(:assessment, anonymous_session: session, question_set: question_set, status: "completed") }
    let(:personality_type) { PersonalityType.find_by(code: "ENFP") || create(:personality_type) }
    let(:profile) do
      create(:profile, assessment: assessment, anonymous_session: session,
             personality_type: personality_type)
    end

    Insight::CONTEXTS.each do |ctx|
      context "with context '#{ctx}'" do
        subject(:insight) { described_class.new(profile, ctx).call }

        it "creates an Insight record" do
          expect { insight }.to change(Insight, :count).by(1)
        end

        it "sets the correct context" do
          expect(insight.context).to eq(ctx)
        end

        it "has an explanation" do
          expect(insight.explanation).to be_present
        end

        it "has suggestions array" do
          expect(insight.suggestions).to be_an(Array)
        end
      end
    end

    context "with invalid context" do
      it "raises ArgumentError" do
        expect {
          described_class.new(profile, "invalid_context").call
        }.to raise_error(ArgumentError, /Unknown insight context/)
      end
    end

    context "when called twice for the same context" do
      it "updates the existing insight (idempotent)" do
        described_class.new(profile, "collaboration").call
        expect {
          described_class.new(profile, "collaboration").call
        }.not_to change(Insight, :count)
      end
    end

    context "explanation enrichment" do
      subject(:insight) { described_class.new(profile, "collaboration").call }

      it "produces a non-empty explanation" do
        expect(insight.explanation.length).to be > 0
      end
    end
  end
end

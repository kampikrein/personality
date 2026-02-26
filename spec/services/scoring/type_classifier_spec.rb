# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scoring::TypeClassifier do
  describe "#call" do
    subject(:result) { described_class.new(assessment, normalized_scores).call }

    let(:assessment) { create(:assessment, question_set: create(:question_set, :with_questions)) }

    context "when all scores are high (>= 50)" do
      let(:normalized_scores) do
        {
          "energy" => 75.0,
          "decision_making" => 80.0,
          "relationship" => 60.0,
          "recovery" => 90.0
        }
      end

      it "returns ENFP" do
        expect(result[:type_code]).to eq("ENFP")
      end

      it "assigns the high letter to each axis" do
        axes = result[:axes]
        expect(axes[:energy][:letter]).to eq("E")
        expect(axes[:decision_making][:letter]).to eq("N")
        expect(axes[:relationship][:letter]).to eq("F")
        expect(axes[:recovery][:letter]).to eq("P")
      end

      it "preserves the original scores on each axis" do
        axes = result[:axes]
        expect(axes[:energy][:score]).to eq(75.0)
        expect(axes[:decision_making][:score]).to eq(80.0)
        expect(axes[:relationship][:score]).to eq(60.0)
        expect(axes[:recovery][:score]).to eq(90.0)
      end
    end

    context "when all scores are low (< 50)" do
      let(:normalized_scores) do
        {
          "energy" => 10.0,
          "decision_making" => 20.0,
          "relationship" => 30.0,
          "recovery" => 40.0
        }
      end

      it "returns ISTJ" do
        expect(result[:type_code]).to eq("ISTJ")
      end

      it "assigns the low letter to each axis" do
        axes = result[:axes]
        expect(axes[:energy][:letter]).to eq("I")
        expect(axes[:decision_making][:letter]).to eq("S")
        expect(axes[:relationship][:letter]).to eq("T")
        expect(axes[:recovery][:letter]).to eq("J")
      end
    end

    context "boundary value: score exactly 50 on each axis" do
      let(:normalized_scores) do
        {
          "energy" => 50.0,
          "decision_making" => 50.0,
          "relationship" => 50.0,
          "recovery" => 50.0
        }
      end

      it "maps to the high letter (>= threshold)" do
        expect(result[:type_code]).to eq("ENFP")
      end

      it "assigns E for energy at 50" do
        expect(result[:axes][:energy][:letter]).to eq("E")
      end

      it "assigns N for decision_making at 50" do
        expect(result[:axes][:decision_making][:letter]).to eq("N")
      end

      it "assigns F for relationship at 50" do
        expect(result[:axes][:relationship][:letter]).to eq("F")
      end

      it "assigns P for recovery at 50" do
        expect(result[:axes][:recovery][:letter]).to eq("P")
      end
    end

    context "boundary value: score 49.9 (just below threshold)" do
      let(:normalized_scores) do
        {
          "energy" => 49.9,
          "decision_making" => 49.9,
          "relationship" => 49.9,
          "recovery" => 49.9
        }
      end

      it "maps to the low letter (< threshold)" do
        expect(result[:type_code]).to eq("ISTJ")
      end
    end

    context "boundary value: score 50.0 (exactly at threshold)" do
      let(:normalized_scores) do
        {
          "energy" => 50.0,
          "decision_making" => 50.0,
          "relationship" => 50.0,
          "recovery" => 50.0
        }
      end

      it "maps to the high letter (>= threshold)" do
        expect(result[:type_code]).to eq("ENFP")
      end
    end

    context "boundary value: score 50.1 (just above threshold)" do
      let(:normalized_scores) do
        {
          "energy" => 50.1,
          "decision_making" => 50.1,
          "relationship" => 50.1,
          "recovery" => 50.1
        }
      end

      it "maps to the high letter (>= threshold)" do
        expect(result[:type_code]).to eq("ENFP")
      end
    end

    context "mixed scores across domains" do
      let(:normalized_scores) do
        {
          "energy" => 30.0,
          "decision_making" => 70.0,
          "relationship" => 25.0,
          "recovery" => 80.0
        }
      end

      it "returns INTP" do
        expect(result[:type_code]).to eq("INTP")
      end

      it "assigns I for low energy" do
        expect(result[:axes][:energy][:letter]).to eq("I")
      end

      it "assigns N for high decision_making" do
        expect(result[:axes][:decision_making][:letter]).to eq("N")
      end

      it "assigns T for low relationship" do
        expect(result[:axes][:relationship][:letter]).to eq("T")
      end

      it "assigns P for high recovery" do
        expect(result[:axes][:recovery][:letter]).to eq("P")
      end
    end

    context "when all scores are nil" do
      let(:normalized_scores) do
        {
          "energy" => nil,
          "decision_making" => nil,
          "relationship" => nil,
          "recovery" => nil
        }
      end

      it "defaults to the low letter for each axis" do
        expect(result[:type_code]).to eq("ISTJ")
      end

      it "stores nil as the score" do
        result[:axes].each_value do |axis|
          expect(axis[:score]).to be_nil
        end
      end
    end

    context "when a single domain score is nil" do
      let(:normalized_scores) do
        {
          "energy" => 75.0,
          "decision_making" => nil,
          "relationship" => 60.0,
          "recovery" => 90.0
        }
      end

      it "defaults that domain to the low letter while classifying others normally" do
        expect(result[:type_code]).to eq("ESFP")
        expect(result[:axes][:energy][:letter]).to eq("E")
        expect(result[:axes][:decision_making][:letter]).to eq("S")
        expect(result[:axes][:relationship][:letter]).to eq("F")
        expect(result[:axes][:recovery][:letter]).to eq("P")
      end
    end

    context "domain to letter pair mapping" do
      it "maps energy to E/I" do
        high = described_class.new(assessment, { "energy" => 60.0, "decision_making" => 50.0, "relationship" => 50.0, "recovery" => 50.0 }).call
        low  = described_class.new(assessment, { "energy" => 40.0, "decision_making" => 50.0, "relationship" => 50.0, "recovery" => 50.0 }).call

        expect(high[:axes][:energy][:letter]).to eq("E")
        expect(low[:axes][:energy][:letter]).to eq("I")
      end

      it "maps decision_making to N/S" do
        high = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 60.0, "relationship" => 50.0, "recovery" => 50.0 }).call
        low  = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 40.0, "relationship" => 50.0, "recovery" => 50.0 }).call

        expect(high[:axes][:decision_making][:letter]).to eq("N")
        expect(low[:axes][:decision_making][:letter]).to eq("S")
      end

      it "maps relationship to F/T" do
        high = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 50.0, "relationship" => 60.0, "recovery" => 50.0 }).call
        low  = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 50.0, "relationship" => 40.0, "recovery" => 50.0 }).call

        expect(high[:axes][:relationship][:letter]).to eq("F")
        expect(low[:axes][:relationship][:letter]).to eq("T")
      end

      it "maps recovery to P/J" do
        high = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 50.0, "relationship" => 50.0, "recovery" => 60.0 }).call
        low  = described_class.new(assessment, { "energy" => 50.0, "decision_making" => 50.0, "relationship" => 50.0, "recovery" => 40.0 }).call

        expect(high[:axes][:recovery][:letter]).to eq("P")
        expect(low[:axes][:recovery][:letter]).to eq("J")
      end
    end

    context "return structure" do
      let(:normalized_scores) do
        {
          "energy" => 72.0,
          "decision_making" => 58.5,
          "relationship" => 65.0,
          "recovery" => 80.0
        }
      end

      it "returns a hash with :type_code and :axes keys" do
        expect(result).to include(:type_code, :axes)
      end

      it "returns axes as a hash of domain symbols" do
        expect(result[:axes].keys).to contain_exactly(:energy, :decision_making, :relationship, :recovery)
      end

      it "returns each axis with :letter and :score keys" do
        result[:axes].each_value do |axis_data|
          expect(axis_data).to include(:letter, :score)
        end
      end
    end
  end
end

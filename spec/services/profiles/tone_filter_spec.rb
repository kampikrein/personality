# frozen_string_literal: true

require "rails_helper"

RSpec.describe Profiles::ToneFilter do
  describe "#call" do
    it "replaces 'you are' with 'you tend toward'" do
      expect(described_class.new("you are introverted").call).to eq("you tend toward introverted")
    end

    it "replaces 'always' with 'often'" do
      expect(described_class.new("You always work hard").call).to eq("You often work hard")
    end

    it "replaces 'never' with 'rarely'" do
      expect(described_class.new("You never give up").call).to eq("You rarely give up")
    end

    it "replaces inability framing" do
      expect(described_class.new("You can't do this").call).to eq("You may find challenging do this")
      expect(described_class.new("unable to focus").call).to eq("may find it challenging to focus")
    end

    it "removes comparative judgments" do
      expect(described_class.new("better than others in this area").call)
        .to eq("others in this area")
      expect(described_class.new("worse than average").call)
        .to eq("average")
    end

    it "preserves case of original match" do
      expect(described_class.new("Always early").call).to eq("Often early")
      expect(described_class.new("always early").call).to eq("often early")
    end

    it "collapses double spaces from removals" do
      # "better than" gets removed, leaving potential double space
      result = described_class.new("much better than average").call
      expect(result).not_to include("  ")
    end

    it "handles blank text" do
      expect(described_class.new("").call).to eq("")
      expect(described_class.new(nil).call).to eq("")
    end

    it "returns text unchanged when no patterns match" do
      expect(described_class.new("You have a creative approach").call)
        .to eq("You have a creative approach")
    end
  end
end

require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe "associations" do
    it "post_tagsを複数持つこと" do
      association = described_class.reflect_on_association(:post_tags)
      expect(association.macro).to eq(:has_many)
    end

    it "投稿をpost_tags経由で複数持つこと" do
      association = described_class.reflect_on_association(:posts)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:post_tags)
    end
  end

  describe "validations" do
    subject(:tag) { described_class.new(name: "rails") }

    it "有効なタグであること" do
      expect(tag).to be_valid
    end

    it "名前がなければ無効になること" do
      tag.name = nil
      expect(tag).to be_invalid
      expect(tag.errors[:name]).to be_present
    end

    it "重複した名前は無効になること" do
      described_class.create!(name: "rails")
      duplicated_tag = described_class.new(name: "rails")

      expect(duplicated_tag).to be_invalid
      expect(duplicated_tag.errors[:name]).to be_present
    end
  end
end

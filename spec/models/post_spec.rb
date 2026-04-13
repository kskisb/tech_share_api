require "rails_helper"

RSpec.describe Post, type: :model do
  let(:user) { User.create!(name: "Alice", email: "alice_post_spec@example.com", password_digest: "digest") }

  describe "associations" do
    it "ユーザーに属すること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "コメントを複数持つこと" do
      association = described_class.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
    end

    it "いいねを複数持つこと" do
      association = described_class.reflect_on_association(:likes)
      expect(association.macro).to eq(:has_many)
    end

    it "post_tagsを複数持つこと" do
      association = described_class.reflect_on_association(:post_tags)
      expect(association.macro).to eq(:has_many)
    end

    it "タグをpost_tags経由で複数持つこと" do
      association = described_class.reflect_on_association(:tags)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:through]).to eq(:post_tags)
    end
  end

  describe "validations" do
    subject(:post_record) { described_class.new(user: user, title: "Rails API", body: "Post body") }

    it "有効な投稿であること" do
      expect(post_record).to be_valid
    end

    it "タイトルがなければ無効になること" do
      post_record.title = nil
      expect(post_record).to be_invalid
      expect(post_record.errors[:title]).to be_present
    end

    it "本文がなければ無効になること" do
      post_record.body = nil
      expect(post_record).to be_invalid
      expect(post_record.errors[:body]).to be_present
    end

    it "ユーザーがなければ無効になること" do
      post_record.user = nil
      expect(post_record).to be_invalid
      expect(post_record.errors[:user]).to be_present
    end
  end
end

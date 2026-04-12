require 'rails_helper'

RSpec.describe Like, type: :model do
  let(:user) { User.create!(name: "Alice", email: "alice_like_spec@example.com", password_digest: "digest") }
  let(:post_record) { Post.create!(user: user, title: "Post title", body: "Post body") }

  describe "associations" do
    it "ユーザーに属すること" do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "投稿に属すること" do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject(:like) { described_class.new(user: user, post: post_record) }

    it "有効ないいねであること" do
      expect(like).to be_valid
    end

    it "ユーザーがなければ無効になること" do
      like.user = nil
      expect(like).to be_invalid
      expect(like.errors[:user]).to be_present
    end

    it "投稿がなければ無効になること" do
      like.post = nil
      expect(like).to be_invalid
      expect(like.errors[:post]).to be_present
    end

    it "同一ユーザーの同一投稿への重複いいねは無効になること" do
      described_class.create!(user: user, post: post_record)
      duplicated_like = described_class.new(user: user, post: post_record)

      expect(duplicated_like).to be_invalid
      expect(duplicated_like.errors[:user_id]).to be_present
    end
  end
end

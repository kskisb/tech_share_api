require "rails_helper"

RSpec.describe Comment, type: :model do
  let(:user) { User.create!(name: "Alice", email: "alice_comment_spec@example.com", password_digest: "digest") }
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
    subject(:comment) { described_class.new(user: user, post: post_record, body: "Nice post!") }

    it "有効なコメントであること" do
      expect(comment).to be_valid
    end

    it "本文がなければ無効になること" do
      comment.body = nil
      expect(comment).to be_invalid
      expect(comment.errors[:body]).to be_present
    end

    it "ユーザーがなければ無効になること" do
      comment.user = nil
      expect(comment).to be_invalid
      expect(comment.errors[:user]).to be_present
    end

    it "投稿がなければ無効になること" do
      comment.post = nil
      expect(comment).to be_invalid
      expect(comment.errors[:post]).to be_present
    end
  end
end

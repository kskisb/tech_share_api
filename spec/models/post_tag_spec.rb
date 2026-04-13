require "rails_helper"

RSpec.describe PostTag, type: :model do
  let(:user) { User.create!(name: "Alice", email: "alice_post_tag_spec@example.com", password_digest: "digest") }
  let(:post_record) { Post.create!(user: user, title: "Post title", body: "Post body") }
  let(:tag) { Tag.create!(name: "rails-post-tag-spec") }

  describe "associations" do
    it "投稿に属すること" do
      association = described_class.reflect_on_association(:post)
      expect(association.macro).to eq(:belongs_to)
    end

    it "タグに属すること" do
      association = described_class.reflect_on_association(:tag)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject(:post_tag) { described_class.new(post: post_record, tag: tag) }

    it "有効な中間レコードであること" do
      expect(post_tag).to be_valid
    end

    it "投稿がなければ無効になること" do
      post_tag.post = nil
      expect(post_tag).to be_invalid
      expect(post_tag.errors[:post]).to be_present
    end

    it "タグがなければ無効になること" do
      post_tag.tag = nil
      expect(post_tag).to be_invalid
      expect(post_tag.errors[:tag]).to be_present
    end

    it "同一投稿への同一タグ付けの重複は無効になること" do
      described_class.create!(post: post_record, tag: tag)
      duplicated_post_tag = described_class.new(post: post_record, tag: tag)

      expect(duplicated_post_tag).to be_invalid
      expect(duplicated_post_tag.errors[:post_id]).to be_present
    end
  end
end

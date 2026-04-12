require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it "ポストを複数持つこと" do
      association = described_class.reflect_on_association(:posts)
      expect(association.macro).to eq(:has_many)
    end

    it "コメントを複数持つこと" do
      association = described_class.reflect_on_association(:comments)
      expect(association.macro).to eq(:has_many)
    end

    it "いいねを複数持つこと" do
      association = described_class.reflect_on_association(:likes)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "validations" do
    subject(:user) { described_class.new(name: "Alice", email: "alice@example.com", password_digest: "password") }

    it "有効なユーザーであること" do
      expect(user).to be_valid
    end

    it "名前が存在しなければ無効になること" do
      user.name = nil
      expect(user).to be_invalid
      expect(user.errors[:name]).to be_present
    end

    it "メールアドレスが存在しなければ無効になること" do
      user.email = nil
      expect(user).to be_invalid
      expect(user.errors[:email]).to be_present
    end

    it "重複したメールアドレスは無効になること" do
      described_class.create!(name: "Bob", email: "dup@example.com", password_digest: "digest")
      duplicated_user = described_class.new(name: "Carol", email: "dup@example.com", password_digest: "digest")

      expect(duplicated_user).to be_invalid
      expect(duplicated_user.errors[:email]).to be_present
    end
  end
end

require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/users" do
    let(:valid_params) do
      {
        user: {
          name: "Alice",
          email: "alice@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        user: {
          name: "",
          email: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "ユーザー登録に成功して201を返すこと" do
      expect do
        post "/api/v1/users", params: valid_params
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json["data"]).to be_present
      expect(json["data"]["user"]).to be_present
      expect(json["data"]["user"]["email"]).to eq("alice@example.com")
    end

    it "不正なパラメータのとき422を返すこと" do
      post "/api/v1/users", params: invalid_params

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "GET /api/v1/me" do
    let(:user) do
      User.create!(
        name: "Bob",
        email: "bob@example.com",
        password_digest: "digest"
      )
    end

    context "認証済みの場合" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it "自分のプロフィールを返して200を返すこと" do
        get "/api/v1/me"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"]).to be_present
        expect(json["data"]["user"]).to be_present
        expect(json["data"]["user"]["id"]).to eq(user.id)
      end
    end

    context "未認証の場合" do
      it "401を返すこと" do
        get "/api/v1/me"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

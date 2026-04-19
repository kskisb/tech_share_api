require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  describe "POST /api/v1/auth/signup" do
    let(:valid_params) do
      { user: { name: "Test User", email: "test@exaple.com", password: "password123", password_confirmation: "password123" } }
    end

    let(:invalid_params) do
      { user: { name: "", email: "test@exaple.com", password: "password123", password_confirmation: "password" } }
    end

    context "有効なパラメータの場合" do
      it "ユーザーが作成されること" do
        expect {
          post "/api/v1/auth/signup", params: valid_params
      }.to change(User, :count).by(1)
      end

      it "201 Created が返り、JWTトークンが含まれていること" do
        post "/api/v1/auth/signup", params: valid_params
        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json["data"]["user"]["name"]).to eq("Test User")
        expect(json["meta"]["token"]).to be_present
      end
    end

    context "無効なパラメータの場合" do
      it "ユーザーが作成されないこと" do
        expect {
          post "/api/v1/auth/signup", params: invalid_params
        }.to change(User, :count).by(0)
      end

      it "422 Unprocessable Entity が返り、エラーが含まれていること" do
        post "/api/v1/auth/signup", params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
        expect(json["errors"].first["code"]).to eq("validation_error")
      end
    end
  end

  describe "GET /api/v1/auth/me" do
    let!(:user) { User.create!(name: "Me User", email: "me@test.com", password: "password123") }
    let(:token) { JsonWebToken.encode(user_id: user.id) }

    context "有効なトークンがある場合" do
      it "ユーザー情報が返ること" do
        get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["user"]["id"]).to eq(user.id)
        expect(json["data"]["user"]["name"]).to eq("Me User")
      end
    end

    context "トークンがない場合" do
      it "401 Unauthorized が返ること" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["errors"].first["code"]).to eq("unauthorized")
      end
    end
  end
end

require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/auth/login" do
    let!(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123") }

    let(:valid_params) do
      { email: "test@example.com", password: "password123" }
    end

    let(:invalid_params) do
      { email: "test@example.com", password: "wrong_password" }
    end

    context "有効な認証情報の場合" do
      it "200 OK が返り、JWTトークンが含まれていること" do
        post "/api/v1/auth/login", params: valid_params
        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"]["user"]["name"]).to eq("Test User")
        expect(json["meta"]["token"]).to be_present
      end
    end

    context "無効な認証情報の場合" do
      it "401 Unauthorized が返ること" do
        post "/api/v1/auth/login", params: invalid_params
        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["errors"].first["code"]).to eq("unauthorized")
        expect(json["errors"].first["message"]).to eq("認証に失敗しました。")
      end
    end
  end
end

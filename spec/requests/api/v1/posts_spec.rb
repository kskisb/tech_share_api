require 'rails_helper'

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/v1/posts" do
    context "有効なパラメータの場合(ログイン済み)" do
      let(:valid_params) do
        { post: { title: "初めての記事", body: "これはテスト記事です" } }
      end

      it "記事が作成され、201 Created が返ること" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["post"]["title"]).to eq("初めての記事")
        expect(json["data"]["post"]["body"]).to eq("これはテスト記事です")
        expect(json["data"]["post"]["user_id"]).to eq(user.id)
      end
    end

    context "無効なパラメータの場合(ログイン済み)" do
      let(:invalid_params) do
        { post: { title: "", body: "タイトルがない" } }
      end

      it "記事は作成されず、422 Unprocessable Content が返ること" do
        expect {
          post "/api/v1/posts", params: invalid_params, headers: headers
        }.not_to change(Post, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"].first["message"]).to eq("Title can't be blank")
      end
    end

    context "ログインしていない場合" do
      let(:valid_params) do
        { post: { title: "未ログイン記事", body: "テスト" } }
      end

      it "401 Unauthorized が返る" do
        post "/api/v1/posts", params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

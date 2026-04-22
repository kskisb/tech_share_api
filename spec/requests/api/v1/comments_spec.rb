require 'rails_helper'

RSpec.describe "Api::V1::Comments", type: :request do
  let(:user) { User.create!(name: "Post Owner", email: "owner@example.com", password: "password123") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  let(:post_record) { Post.create!(title: "記事タイトル", body: "記事本文", user: user) }

  describe "POST /api/v1/comments" do
    context "ログイン済みで有効なパラメータの場合" do
      let(:valid_params) { { comment: { body: "有効なコメント" } } }

      it "コメントが作成され、201 Created が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/comments", params: valid_params, headers: headers
        }.to change(Comment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json["data"]["comment"]["post_id"]).to eq(post_record.id)
        expect(json["data"]["comment"]["user_id"]).to eq(user.id)
        expect(json["data"]["comment"]["body"]).to eq("有効なコメント")
      end
    end

    context "ログイン済みで無効なパラメータの場合" do
      let(:invalid_params) { { comment: { body: "" } } }

      it "コメントは作成されず、422 Unprocessable Entity が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/comments", params: invalid_params, headers: headers
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"].first["code"]).to eq("validation_error")
      end
    end

    context "未ログインの場合" do
      let(:valid_params) { { comment: { body: "有効なコメント" } } }

      it "401 Unauthorized が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/comments", params: valid_params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "存在しない投稿IDの場合" do
      let(:valid_params) { { comment: { body: "有効なコメント" } } }

      it "404 Not Found が返ること" do
        expect {
          post "/api/v1/posts/999999/comments", params: valid_params, headers: headers
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    let(:comment_author) { User.create!(name: "Comment Author", email: "comment_author@example.com", password: "password123") }
    let(:third_user) { User.create!(name: "Third User", email: "third_user@example.com", password: "password123") }

    let(:comment) { Comment.create!(post: post_record, user: comment_author, body: "削除対象コメント") }

    context "コメント投稿者が削除する場合" do
      let(:author_token) { JsonWebToken.encode(user_id: comment_author.id) }
      let(:author_headers) { { "Authorization" => "Bearer #{author_token}" } }

      it "200 OK が返り、コメントが削除されること" do
        comment

        expect {
          delete "/api/v1/posts/#{post_record.id}/comments/#{comment.id}", headers: author_headers
        }.to change(Comment, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "記事投稿者が削除する場合" do
      it "200 OK が返り、コメントが削除されること" do
        comment

        expect {
          delete "/api/v1/posts/#{post_record.id}/comments/#{comment.id}", headers: headers
        }.to change(Comment, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "第三者が削除しようとする場合" do
      let(:third_token) { JsonWebToken.encode(user_id: third_user.id) }
      let(:third_headers) { { "Authorization" => "Bearer #{third_token}" } }

      it "403 Forbidden が返り、コメントは削除されないこと" do
        comment

        expect {
          delete "/api/v1/posts/#{post_record.id}/comments/#{comment.id}", headers: third_headers
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["errors"].first["code"]).to eq("forbidden")
      end
    end

    context "未ログインの場合" do
      it "401 Unauthorized が返ること" do
        comment

        expect {
          delete "/api/v1/posts/#{post_record.id}/comments/#{comment.id}"
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/posts/:id (コメント一覧の取得)" do
    let!(:comment1) { Comment.create!(post: post_record, user: user, body: "コメント1") }
    let!(:comment2) { Comment.create!(post: post_record, user: user, body: "コメント2") }

    it "投稿詳細にコメント一覧が含まれていること" do
      get "/api/v1/posts/#{post_record.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["data"]["post"]["comments"]).to be_an(Array)
      ids = json["data"]["post"]["comments"].map { |c| c["id"] }
      expect(ids).to contain_exactly(comment1.id, comment2.id)

      first_comment = json["data"]["post"]["comments"].first
      expect(first_comment.keys).to include("id", "user_id", "body", "created_at")
    end
  end
end

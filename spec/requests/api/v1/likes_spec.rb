require 'rails_helper'

RSpec.describe "Api::V1::Likes", type: :request do
  let(:user) { User.create!(name: 'Like User', email: 'like_user@example.com', password: 'password123') }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  let(:post_record) { Post.create!(title: 'いいね対象記事', body: '本文', user: user) }

  describe "POST /api/v1/posts/:post_id/likes" do
    context "ログイン済みで、未いいねの場合" do
      it "いいねが作成され、201 Created が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/like", headers: headers
        }.to change(Like, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['data']['like']['post_id']).to eq(post_record.id)
        expect(json['data']['like']['user_id']).to eq(user.id)
        expect(json['data']['like_count']).to eq(1)
      end
    end

    context "ログイン済みで、同じ投稿に重複いいねした場合" do
      before do
        Like.create!(user: user, post: post_record)
      end

      it "いいねは作成されず、422 Unprocessable Content が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/like", headers: headers
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)

        expect(json['errors'].first['code']).to eq('validation_error')
      end
    end

    context "未ログインの場合" do
      it "401 Unauthorized が返ること" do
        expect {
          post "/api/v1/posts/#{post_record.id}/like"
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "存在しない投稿IDの場合" do
      it "404 Not Found が返ること" do
        expect {
          post '/api/v1/posts/999999/like', headers: headers
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/posts/:post_id/likes" do
    let!(:like) { Like.create!(user: user, post: post_record) }

    context 'ログイン済みで、自分のいいねを解除する場合' do
      it 'いいねが削除され、200 OK が返ること' do
        like

        expect {
          delete "/api/v1/posts/#{post_record.id}/like", headers: headers
        }.to change(Like, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data']['like_count']).to eq(0)
      end
    end

    context '未ログインの場合' do
      it '401 Unauthorized が返ること' do
        like

        expect {
          delete "/api/v1/posts/#{post_record.id}/like"
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '自分のいいねが存在しない場合' do
      let(:other_user) { User.create!(name: 'Other User', email: 'other_like_user@example.com', password: 'password123') }

      before do
        like.destroy
        Like.create!(user: other_user, post: post_record)
      end

      it '404 Not Found が返り、他人のいいねは削除されないこと' do
        expect {
          delete "/api/v1/posts/#{post_record.id}/like", headers: headers
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context '存在しない投稿IDの場合' do
      it '404 Not Found が返ること' do
        expect {
          delete '/api/v1/posts/999999/like', headers: headers
        }.not_to change(Like, :count)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/posts (like_count)' do
    let!(:post_with_two_likes) do
      Post.create!(title: '2いいね記事', body: '本文', user: user)
    end
    let!(:post_without_likes) do
      Post.create!(title: '0いいね記事', body: '本文', user: user)
    end

    before do
      other_user = User.create!(name: 'Like Another', email: 'like_another@example.com', password: 'password123')
      Like.create!(user: user, post: post_with_two_likes)
      Like.create!(user: other_user, post: post_with_two_likes)
    end

    it '記事一覧で各記事の like_count が返ること' do
      get '/api/v1/posts'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      posts = json['data']['posts']
      two_likes_post = posts.find { |p| p['id'] == post_with_two_likes.id }
      zero_likes_post = posts.find { |p| p['id'] == post_without_likes.id }

      expect(two_likes_post['like_count']).to eq(2)
      expect(zero_likes_post['like_count']).to eq(0)
    end
  end

  describe 'GET /api/v1/posts/:id (like_count)' do
    let(:target_post) { Post.create!(title: '詳細対象記事', body: '本文', user: user) }

    before do
      other_user = User.create!(name: 'Detail Like User', email: 'detail_like_user@example.com', password: 'password123')
      Like.create!(user: user, post: target_post)
      Like.create!(user: other_user, post: target_post)
    end

    it '記事詳細で like_count が返ること' do
      get "/api/v1/posts/#{target_post.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data']['post']['like_count']).to eq(2)
    end
  end
end

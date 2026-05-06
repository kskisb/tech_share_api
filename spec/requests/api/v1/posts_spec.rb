require 'rails_helper'

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password") }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "GET /api/v1/posts" do
    before do
      Post.create!(title: "古い記事", body: "テスト", user: user, created_at: 2.days.ago)
      Post.create!(title: "新しい記事", body: "テスト", user: user, created_at: 1.day.ago)
    end

    it "記事一覧が新着順(降順)で取得でき、200 OK が返り、未ログインでも見られること" do
      get "/api/v1/posts"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["data"]["posts"].length).to eq(2)

      expect(json["data"]["posts"][0]["title"]).to eq("新しい記事")
      expect(json["data"]["posts"][1]["title"]).to eq("古い記事")
    end

    context "q パラメータで検索する場合" do
      before do
        Post.destroy_all
        Post.create!(title: "RailsでAPIを作る", body: "実装の手順", user: user)
        Post.create!(title: "JavaScript入門", body: "Railsと連携する", user: user)
        Post.create!(title: "Go言語の基本", body: "サーバーサイド", user: user)
      end

      it "title/body の部分一致で絞り込みできること" do
        get "/api/v1/posts", params: { q: "Rails" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["posts"].length).to eq(2)
        expect(json["data"]["posts"].map { |post| post["title"] }).to contain_exactly(
          "RailsでAPIを作る",
          "JavaScript入門"
        )
      end
    end

    context "q と tag を同時に指定する場合" do
      let!(:rails_tag) { Tag.create!(name: "rails") }
      let!(:react_tag) { Tag.create!(name: "react") }

      before do
        Post.destroy_all

        post1 = Post.create!(title: "Railsで検索API", body: "qとtagを実装", user: user)
        post2 = Post.create!(title: "Railsで画面構築", body: "検索UI", user: user)
        post3 = Post.create!(title: "Reactで検索UI", body: "hooks", user: user)

        PostTag.create!(post: post1, tag: rails_tag)
        PostTag.create!(post: post2, tag: react_tag)
        PostTag.create!(post: post3, tag: rails_tag)
      end

      it "両条件を満たす記事だけ返すこと" do
        get "/api/v1/posts", params: { q: "Rails", tag: "rails" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["posts"].length).to eq(1)
        expect(json["data"]["posts"][0]["title"]).to eq("Railsで検索API")
      end
    end
  end

  describe "GET /api/v1/posts/:id" do
    let(:post_record) { Post.create!(title: "記事タイトル", body: "記事の本文", user: user) }

    context "存在する記事IDの場合" do
      it "200 OK が返り、該当記事の詳細が取得できること" do
        get "/api/v1/posts/#{post_record.id}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["post"]["id"]).to eq(post_record.id)
        expect(json["data"]["post"]["title"]).to eq("記事タイトル")
        expect(json["data"]["post"]["body"]).to eq("記事の本文")
        expect(json["data"]["post"]["user_id"]).to eq(user.id)
      end
    end

    context "存在しない記事IDの場合" do
      it "404 Not Found が返ること" do
        get "/api/v1/posts/9999"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

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

    context "複数タグを指定して作成する場合" do
      let(:valid_params) do
        { post: { title: "タグ付き記事", body: "本文", tag_names: [ "rails", "api" ] } }
      end

      it "複数タグが付与され、201 Created が返ること" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["data"]["post"]["title"]).to eq("タグ付き記事")

        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to contain_exactly("rails", "api")
      end
    end

    context "既存タグ名を指定した場合" do
      let!(:existing_tag) { Tag.create!(name: "react") }
      let(:valid_params) do
        { post: { title: "React利用", body: "本文", tag_names: [ "react" ] } }
      end

      it "新規タグを作成せず、既存タグを再利用すること" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)
        .and change(Tag, :count).by(0)

        expect(response).to have_http_status(:created)
        created_post = Post.last
        expect(created_post.tags.first.id).to eq(existing_tag.id)
      end
    end

    context "タグ名が混在している場合（既存+新規）" do
      let!(:existing_tag) { Tag.create!(name: "ruby") }
      let(:valid_params) do
        { post: { title: "Ruby記事", body: "本文", tag_names: [ "ruby", "rails" ] } }
      end

      it "既存タグは再利用し、新規タグは作成すること" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)
        .and change(Tag, :count).by(1)

        expect(response).to have_http_status(:created)
        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to contain_exactly("ruby", "rails")
      end
    end

    context "重複したタグ名を指定した場合" do
      let(:valid_params) do
        { post: { title: "重複タグ", body: "本文", tag_names: [ "python", "python" ] } }
      end

      it "重複を除いて1つのタグとして扱うこと" do
        expect {
          post "/api/v1/posts", params: valid_params, headers: headers
        }.to change(Post, :count).by(1)
        .and change(Tag, :count).by(1)

        created_post = Post.last
        expect(created_post.tags.size).to eq(1)
        expect(created_post.tags.first.name).to eq("python")
      end
    end

    context "空文字タグを含む場合" do
      let(:invalid_params) do
        { post: { title: "空タグ", body: "本文", tag_names: [ "rails", "" ] } }
      end

      it "422 Unprocessable Content が返ること" do
        expect {
          post "/api/v1/posts", params: invalid_params, headers: headers
        }.not_to change(Post, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"].first["code"]).to eq("validation_error")
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

  describe "PATCH /api/v1/posts/:id" do
    let!(:my_post) { Post.create(title: "自分の記事", body: "本文", user: user) }
    let(:other_user) { User.create!(name: "Other", email: "other@example.com", password: "password") }
    let!(:others_post) { Post.create!(title: "他人の記事", body: "本文", user: other_user) }

    let(:valid_params) { { post: { title: "更新されたタイトル", body: "更新された本文" } } }

    context "ログイン済みで、自分の記事を更新する場合" do
      it "200 OK が返り、記事が更新されること" do
        patch "/api/v1/posts/#{my_post.id}", params: valid_params, headers: headers

        expect(response).to have_http_status(:ok)
        my_post.reload
        expect(my_post.title).to eq("更新されたタイトル")
        expect(my_post.body).to eq("更新された本文")

        json = JSON.parse(response.body)
        expect(json["data"]["post"]["title"]).to eq("更新されたタイトル")
      end
    end

    context "ログイン済みだが、他人の記事を更新しようとした場合" do
      it "403 Forbidden が返り、記事は更新されないこと" do
        patch "/api/v1/posts/#{others_post.id}", params: valid_params, headers: headers

        expect(response).to have_http_status(:forbidden)
        others_post.reload
        expect(others_post.title).not_to eq("更新されたタイトル")

        json = JSON.parse(response.body)
        expect(json["errors"].first["message"]).to eq("権限がありません")
      end
    end

    context "ログインしていない場合" do
      it "401 Unauthorized が返ること" do
        patch "/api/v1/posts/#{my_post.id}", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "ログイン済みで、無効なパラメータを送信した場合" do
      let(:invalid_params) { { post: { title: "", body: "本文" } } }

      it "422 Unprocessable Content が返り、更新されないこと" do
        patch "/api/v1/posts/#{my_post.id}", params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        my_post.reload
        expect(my_post.title).not_to eq("") # 空になっていないこと

        json = JSON.parse(response.body)
        expect(json["errors"].first["message"]).to eq("Title can't be blank")
      end
    end

    context "ログイン済みで、自分の記事のタグを更新する場合" do
      let(:rails_tag) { Tag.create!(name: "rails") }
      let(:vue_tag) { Tag.create!(name: "vue") }

      before do
        PostTag.create!(post: my_post, tag: rails_tag)
      end

      it "タグが置き換わること" do
        params = { post: { title: "更新タイトル", body: "更新本文", tag_names: [ "vue" ] } }

        patch "/api/v1/posts/#{my_post.id}", params: params, headers: headers

        expect(response).to have_http_status(:ok)
        my_post.reload
        expect(my_post.tags.pluck(:name)).to contain_exactly("vue")
        expect(my_post.tags.pluck(:name)).not_to include("rails")
      end
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    let!(:my_post) { Post.create!(title: "自分の記事", body: "本文", user: user) }
    let(:other_user) { User.create!(name: "Other", email: "other@example.com", password: "password") }
    let!(:others_post) { Post.create!(title: "他人の記事", body: "本文", user: other_user) }

    context "ログイン済みで、自分の記事を削除する場合" do
      it "200 OK が返り、記事が削除されること" do
        expect {
          delete "/api/v1/posts/#{my_post.id}", headers: headers
        }.to change(Post, :count).by(-1)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"]["message"]).to eq("記事を削除しました")
      end
    end

    context "ログイン済みだが、他人の記事を削除しようとした場合" do
      it "403 Forbidden が返り、記事は削除されないこと" do
        expect {
          delete "/api/v1/posts/#{others_post.id}", headers: headers
        }.not_to change(Post, :count)

        expect(response).to have_http_status(:forbidden)

        json = JSON.parse(response.body)
        expect(json["errors"].first["message"]).to eq("権限がありません")
      end
    end

    context "ログインしていない場合" do
      it "401 Unauthorized が返ること" do
        delete "/api/v1/posts/#{my_post.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

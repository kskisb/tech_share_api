require 'rails_helper'

RSpec.describe "Api::V1::Tags", type: :request do
  let(:user) { User.create!(name: "Tag User", email: "tag_user@example.com", password: "password123") }

  describe "GET /api/v1/tags" do
    context "タグが1つ存在する場合" do
      let!(:rails_tag) { Tag.create!(name: "rails") }
      let!(:ruby_tag) { Tag.create!(name: "ruby") }

      it "200 OK を返し、タグ一覧を取得できること" do
        get "/api/v1/tags"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]).to be_present
        expect(json["data"]["tags"]).to be_an(Array)
        expect(json["data"]["tags"].size).to eq(2)

        names = json["data"]["tags"].map { |tag| tag["name"] }
        expect(names).to contain_exactly(rails_tag.name, ruby_tag.name)
      end
    end

    context "タグが複数存在する場合" do
      let!(:rails_tag) { Tag.create!(name: "rails") }
      let!(:web_tag) { Tag.create!(name: "web") }
      let!(:backend_tag) { Tag.create!(name: "backend") }

      let!(:multi_tag_post) do
        post = Post.create!(title: "複数タグの記事", body: "複数タグのテスト", user: user)
        PostTag.create!(post: post, tag: rails_tag)
        PostTag.create!(post: post, tag: web_tag)
        PostTag.create!(post: post, tag: backend_tag)
        post
      end

      let!(:single_tag_post) do
        post = Post.create!(title: "Rails Only", body: "単一タグのテスト", user: user)
        PostTag.create!(post: post, tag: rails_tag)
        post
      end

      it "複数タグを持つ投稿が tag filter でマッチすること（rails での検索）" do
        get "/api/v1/posts", params: { tag: "rails" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        ids = json["data"]["posts"].map { |p| p["id"] }
        expect(ids).to include(multi_tag_post.id)
        expect(ids).to include(single_tag_post.id)
      end

      it "複数タグを持つ投稿が tag filter でマッチすること（web での検索）" do
        get "/api/v1/posts", params: { tag: "web" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        ids = json["data"]["posts"].map { |p| p["id"] }
        expect(ids).to include(multi_tag_post.id)
        expect(ids).not_to include(single_tag_post.id)
      end
    end

    context "タグが存在しない場合" do
      it "200 OK を返し、空配列を返すこと" do
        get "/api/v1/tags"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["tags"]).to eq([])
      end
    end
  end

  describe "GET /api/v1/posts?tag=xxx" do
    let!(:rails_tag) { Tag.create!(name: "rails") }
    let!(:ruby_tag) { Tag.create!(name: "ruby") }

    let!(:old_rails_post) do
      Post.create!(title: "Old Rails", body: "old rails body", user: user, created_at: 2.days.ago)
    end

    let!(:new_rails_post) do
      Post.create!(title: "New Rails", body: "new rails body", user: user, created_at: 1.day.ago)
    end

    let!(:ruby_post) do
      Post.create!(title: "Ruby Only", body: "ruby body", user: user, created_at: 3.days.ago)
    end

    before do
      PostTag.create!(post: old_rails_post, tag: rails_tag)
      PostTag.create!(post: new_rails_post, tag: rails_tag)
      PostTag.create!(post: ruby_post, tag: ruby_tag)
    end

    context "指定タグが存在する場合" do
      it "該当タグの投稿のみを新着順で返すこと" do
        get "/api/v1/posts", params: { tag: "rails" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["posts"]).to be_an(Array)
        expect(json["data"]["posts"].size).to eq(2)

        ids = json["data"]["posts"].map { |post| post["id"] }
        expect(ids).to eq([ new_rails_post.id, old_rails_post.id ])
        expect(ids).not_to include(ruby_post.id)
      end
    end

    context "指定タグが存在しない場合" do
      it "200 OK を返し、空配列を返すこと" do
        get "/api/v1/posts", params: { tag: "unknown-tag" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json["data"]["posts"]).to eq([])
      end
    end
  end
end

require 'swagger_helper'

RSpec.describe 'Api::V1::Posts', type: :request do
  path '/api/v1/posts' do
    get '記事一覧を取得する' do
      tags 'Posts'
      produces 'application/json'

      parameter name: :tag,
                in: :query,
                required: false,
                schema: { type: :string },
                description: 'タグ名で記事を絞り込む (部分一致ではなく完全一致)'

      response '200', '取得成功 (新着順)' do
        schema type: :object,
               required: %w[data],
               properties: {
                 data: {
                   type: :object,
                   required: %w[posts],
                   properties: {
                     posts: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/Post' }
                     }
                   }
                 }
               }

        let(:tag) { nil }

        before do
          user = User.create!(name: 'author', email: 'author@example.com', password: 'password')
          Post.create!(title: '古い記事', body: 'old', user: user, created_at: 2.days.ago)
          Post.create!(title: '新しい記事', body: 'new', user: user, created_at: 1.day.ago)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['posts'].length).to eq(2)
          expect(json['data']['posts'].first['title']).to eq('新しい記事')
        end
      end

      response '200', 'タグ絞り込み成功' do
        schema type: :object,
               required: %w[data],
               properties: {
                 data: {
                   type: :object,
                   required: %w[posts],
                   properties: {
                     posts: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/Post' }
                     }
                   }
                 }
               }

        let(:tag) { 'rails' }

        before do
          user = User.create!(name: 'author2', email: 'author2@example.com', password: 'password')
          rails_tag = Tag.create!(name: 'rails')
          ruby_tag = Tag.create!(name: 'ruby')

          rails_post = Post.create!(title: 'Rails Post', body: 'body', user: user)
          ruby_post  = Post.create!(title: 'Ruby Post',  body: 'body', user: user)
          PostTag.create!(post: rails_post, tag: rails_tag)
          PostTag.create!(post: ruby_post,  tag: ruby_tag)
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['posts'].length).to eq(1)
          expect(json['data']['posts'].first['title']).to eq('Rails Post')
        end
      end
    end
  end

  path '/api/v1/posts/{id}' do
    get '記事詳細を取得する' do
      tags 'Posts'
      produces 'application/json'

      parameter name: :id,
                in: :path,
                required: true,
                schema: { type: :integer },
                description: '記事 ID'

      response '200', '取得成功 (コメント一覧を含む)' do
        schema type: :object,
               required: %w[data],
               properties: {
                 data: {
                   type: :object,
                   required: %w[post],
                   properties: {
                     post: { '$ref' => '#/components/schemas/PostWithComments' }
                   }
                 }
               }

        let(:user) do
          User.create!(name: 'show-user', email: 'show-user@example.com', password: 'password')
        end
        let(:record) do
          Post.create!(title: '詳細タイトル', body: '詳細本文', user: user)
        end
        let(:id) { record.id }

        before do
          Comment.create!(post: record, user: user, body: 'コメント1')
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['post']['id']).to eq(record.id)
          expect(json['data']['post']['comments'].length).to eq(1)
        end
      end

      response '404', '記事が存在しない' do
        schema '$ref' => '#/components/schemas/ErrorResponse'

        let(:id) { 999_999 }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['errors'].first['code']).to eq('not_found')
        end
      end
    end
  end
end

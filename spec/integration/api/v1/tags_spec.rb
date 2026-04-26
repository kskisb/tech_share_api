require 'swagger_helper'

RSpec.describe 'Api::V1::Tags', type: :request do
  path '/api/v1/tags' do
    get 'タグ一覧を取得する' do
      tags 'Tags'
      produces 'application/json'

      response '200', '取得成功' do
        schema type: :object,
               required: %w[data],
               properties: {
                 data: {
                   type: :object,
                   required: %w[tags],
                   properties: {
                     tags: {
                       type: :array,
                       items: { '$ref' => '#/components/schemas/Tag' }
                     }
                   }
                 }
               }

        before do
          Tag.create!(name: 'rails')
          Tag.create!(name: 'react')
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json['data']['tags'].size).to eq(2)
        end
      end
    end
  end
end

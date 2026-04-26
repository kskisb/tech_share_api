# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.3',
      info: {
        title: 'TechShare API',
        version: 'v1',
        description: 'TechShare のバックエンド API v1'
      },
      servers: [
        { url: 'http://localhost:3001', description: 'local (docker)' }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        },
        schemas: {
          Error: {
            type: :object,
            required: %w[code message],
            properties: {
              code: { type: :string, example: 'validation_error' },
              message: { type: :string, example: "Title can't be blank" }
            }
          },
          ErrorResponse: {
            type: :object,
            required: %w[errors],
            properties: {
              errors: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Error' }
              }
            }
          },
          Tag: {
            type: :object,
            required: %w[id name],
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'rails' },
              created_at: { type: :string, format: 'date-time' }
            }
          },
          Post: {
            type: :object,
            required: %w[id user_id title body created_at tags like_count liked_by_current_user],
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              title: { type: :string },
              body: { type: :string },
              created_at: { type: :string, format: 'date-time' },
              tags: {
                type: :array,
                items: { '$ref' => '#/components/schemas/Tag' }
              },
              like_count: { type: :integer },
              liked_by_current_user: { type: :boolean }
            }
          },
          PostWithComments: {
            allOf: [
              { '$ref' => '#/components/schemas/Post' },
              {
                type: :object,
                required: %w[comments],
                properties: {
                  comments: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/Comment' }
                  }
                }
              }
            ]
          },
          Comment: {
            type: :object,
            required: %w[id user_id body created_at],
            properties: {
              id: { type: :integer },
              user_id: { type: :integer },
              body: { type: :string },
              created_at: { type: :string, format: 'date-time' }
            }
          },
          CreatePostRequest: {
            type: :object,
            required: %w[post],
            properties: {
              post: {
                type: :object,
                required: %w[title body],
                properties: {
                  title: { type: :string, example: 'Rails API' },
                  body: { type: :string, example: 'Post body' },
                  tag_names: {
                    type: :array,
                    items: { type: :string },
                    example: [ 'rails', 'api' ]
                  }
                }
              }
            }
          },
          UpdatePostRequest: {
            type: :object,
            required: %w[post],
            properties: {
              post: {
                type: :object,
                properties: {
                  title: { type: :string },
                  body: { type: :string },
                  tag_names: { type: :array, items: { type: :string } }
                }
              }
            }
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end

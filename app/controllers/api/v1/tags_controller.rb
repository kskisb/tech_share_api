class Api::V1::TagsController < ApplicationController
  def index
    tags = Tag.all

    render json: {
      data: {
        tags: tags.map do |tag|
          {
            id: tag.id,
            name: tag.name,
            created_at: tag.created_at
          }
        end
      }
    }, status: :ok
  end
end

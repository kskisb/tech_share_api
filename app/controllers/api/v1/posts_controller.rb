class Api::V1::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create ]

  def index
    posts = Post.order(created_at: :desc)

    render json: {
      data: {
        posts: posts.map do |post|
          {
            id: post.id,
            user_id: post.user_id,
            title: post.title,
            body: post.body,
            created_at: post.created_at
          }
        end
      }
    }, status: :ok
  end

  def create
    post = current_user.posts.build(post_params)

    if post.save
      render json: {
        data: {
          post: {
            id: post.id,
            user_id: post.user_id,
            title: post.title,
            body: post.body,
            created_at: post.created_at
          }
        }
      }, status: :created
    else
      render json: {
        errors: post.errors.full_messages.map do |msg|
          { code: "validation_error", message: msg }
        end
      }, status: :unprocessable_content
    end
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
end

class Api::V1::LikesController < ApplicationController
  before_action :authenticate_user!

  def create
    post = Post.find(params[:post_id])
    like = post.likes.build(user: current_user)

    if like.save
      render json: {
        data: {
          like: {
            id: like.id,
            post_id: like.post_id,
            user_id: like.user_id,
            created_at: like.created_at
          },
          like_count: post.likes.count
        }
      }, status: :created
    else
      render json: {
        errors: like.errors.full_messages.map do |msg|
          { code: "validation_error", message: msg }
        end
      }, status: :unprocessable_content
    end
  end

  def destroy
    like = Like.find_by(post_id: params[:post_id], user_id: current_user.id)

    unless like
      return render json: {
        errors: [
          { code: "not_found", message: "いいねが見つかりません" }
        ]
      }, status: :not_found
    end

    like.destroy

    render json: {
      data: {
        like_count: like.post.likes.count,
        message: "いいねを取り消しました"
      }
    }, status: :ok
  end
end

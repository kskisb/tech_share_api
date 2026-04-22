class Api::V1::CommentsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :destroy ]

  def create
    post = Post.find(params[:post_id])
    comment = post.comments.build(comment_params.merge(user: current_user))

    if comment.save
      render json: {
        data: {
          comment: {
            id: comment.id,
            post_id: comment.post_id,
            user_id: comment.user_id,
            body: comment.body,
            created_at: comment.created_at
          }
        }
      }, status: :created
    else
      render json: {
        errors: comment.errors.full_messages.map do |msg|
          { code: "validation_error", message: msg }
        end
      }, status: :unprocessable_content
    end
  end

  def destroy
    comment = Comment.find(params[:id])

    unless comment.user_id == current_user.id || comment.post.user_id == current_user.id
      return render json: {
        errors: [
          { code: "forbidden", message: "権限がありません" }
        ]
      }, status: :forbidden
    end

    comment.destroy

    render json: {
      data: {
        message: "コメントを削除しました"
      }
    }, status: :ok
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end

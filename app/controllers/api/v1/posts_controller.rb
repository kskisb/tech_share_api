class Api::V1::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]

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

  def show
    post = Post.includes(:comments).find(params[:id])

    render json: {
      data: {
        post: {
          id: post.id,
          user_id: post.user_id,
          title: post.title,
          body: post.body,
          created_at: post.created_at,
          comments: post.comments.map do |comment|
            {
              id: comment.id,
              user_id: comment.user_id,
              body: comment.body,
              created_at: comment.created_at
            }
          end
        }
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

  def update
    begin
      post = current_user.posts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      # 他人の記事や存在しない記事にアクセスしようとした場合は共通で 403 Forbidden にする
      return render json: {
        errors: [ { code: "forbidden", message: "権限がありません" } ]
      }, status: :forbidden
    end

    if post.update(post_params)
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
      }, status: :ok
    else
      render json: {
        errors: post.errors.full_messages.map do |msg|
          { code: "validation_error", message: msg }
        end
      }, status: :unprocessable_content
    end
  end

  def destroy
    begin
      post = current_user.posts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render json: {
        errors: [ { code: "forbidden", message: "権限がありません" } ]
      }, status: :forbidden
    end

    post.destroy

    render json: {
      data: {
        message: "記事を削除しました"
      }
    }, status: :ok
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
end

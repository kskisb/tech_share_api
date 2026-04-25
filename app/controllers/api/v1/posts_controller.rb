class Api::V1::PostsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]

  def index
    posts = Post.includes(:tags).order(created_at: :desc)
    posts = posts.joins(:tags).where(tags: { name: params[:tag] }).distinct if params[:tag].present?

    render json: {
      data: {
        posts: posts.map { |post| serialize_post(post) }
      }
    }, status: :ok
  end

  def show
    post = Post.includes(:comments, :tags).find(params[:id])

    render json: {
      data: {
        post: serialize_post(post, include_comments: true)
      }
    }, status: :ok
  end

  def create
    permitted = post_params
    post = current_user.posts.build(permitted.except(:tag_names))

    tag_names_result = extract_tag_names(permitted)
    return render_tag_validation_error if tag_names_result == :invalid

    ActiveRecord::Base.transaction do
      post.save!
      assign_tags(post, tag_names_result) if tag_names_result
    end

    render json: {
      data: {
        post: serialize_post(post)
      }
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
  end

  def update
    begin
      post = current_user.posts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return render json: {
        errors: [ { code: "forbidden", message: "権限がありません" } ]
      }, status: :forbidden
    end

    permitted = post_params
    tag_names_result = extract_tag_names(permitted)
    return render_tag_validation_error if tag_names_result == :invalid

    ActiveRecord::Base.transaction do
      post.update!(permitted.except(:tag_names))
      assign_tags(post, tag_names_result) if tag_names_result
    end

    render json: {
      data: {
        post: serialize_post(post)
      }
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render_validation_errors(e.record)
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
    params.require(:post).permit(:title, :body, tag_names: [])
  end

  def extract_tag_names(permitted)
    return nil unless permitted.key?(:tag_names)

    names = Array(permitted[:tag_names]).map { |name| name.to_s.strip }
    return :invalid if names.any?(&:blank?)

    names.uniq
  end

  def assign_tags(post, tag_names)
    tags = tag_names.map { |name| Tag.find_or_create_by!(name: name)}
    post.tags = tags
  end

  def serialize_post(post, include_comments: false)
    result = {
      id: post.id,
      user_id: post.user_id,
      title: post.title,
      body: post.body,
      created_at: post.created_at,
      tags: post.tags.map do |tag|
        {
          id: tag.id,
          name: tag.name
        }
      end
    }

    if include_comments
      result[:comments] = post.comments.map do |comment|
        {
          id: comment.id,
          user_id: comment.user_id,
          body: comment.body,
          created_at: comment.created_at
        }
      end
    end

    result
  end

  def render_validation_errors(record)
    render json: {
      errors: record.errors.full_messages.map { |msg| { code: "validation_error", message: msg } }
    }, status: :unprocessable_content
  end

  def render_tag_validation_error
    render json: {
      errors: [ { code: "validation_error", message: "Tag names can't include blank values" } ]
    }, status: :unprocessable_content
  end
end

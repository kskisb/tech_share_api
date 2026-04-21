class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def authenticate_user!
    header = request.headers["Authorization"]
    token = header.split(" ").last if header

    decoded = JsonWebToken.decode(token)
    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end

    unless @current_user
      render json: {
        errors: [
          { code: "unauthorized", message: "認証が必要です。" }
        ]
      }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  private

  def render_not_found
    render json: {
      errors: [
        { code: "not_found", message: "指定されたリソースが見つかりません" }
      ]
    }, status: :not_found
  end
end

class Api::V1::SessionsController < ApplicationController
  def create
    user = User.find_by(email: login_params[:email])

    if user&.authenticate(login_params[:password])
      token = JsonWebToken.encode(user_id: user.id)

      render json: {
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email
          }
        },
        meta: {
          token: token
        }
      }, status: :ok
    else
      render json: {
        errors: [
          { code: "unauthorized", message: "認証に失敗しました。" }
        ]
      }, status: :unauthorized
    end
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end

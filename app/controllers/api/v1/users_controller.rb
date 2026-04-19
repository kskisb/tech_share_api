class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :me ]
  def create
    user = User.new(user_params)

    if user.save
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
      }, status: :created
    else
      render json: {
        errors: user.errors.full_messages.map do |msg|
          { code: "validation_error", message: msg }
        end
      }, status: :unprocessable_content
    end
  end

  def me
    render json: {
      data: {
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email
        }
      }
    }, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end

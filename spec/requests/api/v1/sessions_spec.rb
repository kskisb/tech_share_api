require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  describe "POST /api/v1/session" do
    let!(:user) do
      User.create!(
        name: "Alice",
        email: "alice_session_spec@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    let(:valid_params) do
      {
        session: {
          email: user.email,
          password: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        session: {
          email: user.email,
          password: "wrong-password"
        }
      }
    end

    it "ログインに成功して200を返すこと" do
      post "/api/v1/session", params: valid_params

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["data"]).to be_present
      expect(json["data"]["user"]).to be_present
      expect(json["data"]["token"]).to be_present
      expect(json["data"]["user"]["email"]).to eq(user.email)
    end

    it "認証に失敗したら401を返すこと" do
      post "/api/v1/session", params: invalid_params

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end
  end

  describe "DELETE /api/v1/session" do
    let(:user) do
      User.create!(
        name: "Bob",
        email: "bob_session_spec@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    context "認証済みの場合" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
      end

      it "ログアウトに成功して204を返すこと" do
        delete "/api/v1/session"

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end

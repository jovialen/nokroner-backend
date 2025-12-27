class SessionsController < ApplicationController
  before_action :set_session, only: %i[ show destroy ]
  allow_unauthenticated_access only: %i[ create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: 'Try again later.' }

  # GET /sessions
  def index
    @sessions = Session.created_by_user

    render json: @sessions
  end

  # GET /sessions/1
  def show
    render json: @session
  end

  # POST /sessions
  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      @session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
      render json: @session, status: :created
    else
      render json: { error: 'Invalid username or password' }, status: :unauthorized
    end
  end

  # DELETE /sessions/1
  def destroy
    @session.destroy
    head :no_content
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_session
    @session = Session.created_by_user.find(params.expect(:id))
  end
end

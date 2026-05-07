class ApplicationController < ActionController::API
  include Authentication

  rescue_from ActionController::RoutingError, with: :render_not_found
  rescue_from AbstractController::ActionNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from ActiveRecord::RecordNotSaved, with: :render_unprocessable_entity

  private

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_unprocessable_entity(exception)
    render json: { errors: exception.record.errors.full_messages, full_errors: exception.record.errors }, status: :unprocessable_entity
  end
end

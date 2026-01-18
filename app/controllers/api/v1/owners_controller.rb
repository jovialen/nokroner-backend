class Api::V1::OwnersController < ApplicationController
  before_action :set_owner, only: %i[ show update destroy ]

  def index
    render json: Owner.created_by_user
  end

  def show
    render json: @owner
  end

  def create
    @owner = Owner.new(owner_params)
    @owner.created_by = Current.user

    if @owner.save
      render json: @owner, status: :created, location: api_v1_owner_path(@owner)
    else
      render json: { errors: @owner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @owner.update(owner_params)
      render json: @owner
    else
      render json: { errors: @owner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    unless Current.user.owner == @owner
      @owner.destroy
      head(:ok)
    else
      render json: { error: "cannot delete user owner. delete user instead" }, status: :bad_request
    end
  end

  private

  def set_owner
    @owner = Owner.created_by_user.find(params[:id])
  end

  def owner_params
    params.expect(owner: [ :name ])
  end
end

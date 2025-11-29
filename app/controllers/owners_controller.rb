class OwnersController < ApplicationController
  before_action :set_owner, only: %i[ show update destroy ]

  # GET /owners
  def index
    @owners = Owner.created_by_user

    render json: @owners
  end

  # GET /owners/1
  def show
    render json: @owner
  end

  # POST /owners
  def create
    @owner = Owner.new(owner_params)
    @owner.creator = Current.user
    @owner.is_user = false

    if @owner.save
      render json: @owner, status: :created, location: @owner
    else
      render json: @owner.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /owners/1
  def update
    if @owner.update(owner_params)
      render json: @owner
    else
      render json: @owner.errors, status: :unprocessable_content
    end
  end

  # DELETE /owners/1
  def destroy
    @owner.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_owner
    @owner = Owner.created_by_user.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def owner_params
    params.expect(owner: [ :name, :net_worth ])
  end
end

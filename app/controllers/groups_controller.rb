class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show update destroy ]

  # GET /groups
  def index
    @groups = Current.user.all_groups
    render json: @groups
  end

  # GET /groups/1
  def show
    render json: @group
  end

  # POST /groups
  def create
    @group = Current.user.all_groups.create!(group_params)
    render json: @group, status: :created, location: @group
  end

  # PATCH/PUT /groups/1
  def update
    @group.update!(group_params)
    render json: @group
  end

  # DELETE /groups/1
  def destroy
    @group.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_group
      @group = Current.user.all_groups.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def group_params
      params.expect(group: [ :name, :parent_id ])
    end
end

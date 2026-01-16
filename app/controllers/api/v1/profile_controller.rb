class Api::V1::ProfileController < ApplicationController
  before_action :set_profile, only: [ :show, :update ]

  def show
    render json: @profile.as_json(
      methods: :age
    )
  end

  def update
    if @profile.update(profile_params)
      render json: @profile
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Current.user.profile
  end

  def profile_params
    params.expect(profile: [ :first_name, :last_name, :date_of_birth ])
  end
end

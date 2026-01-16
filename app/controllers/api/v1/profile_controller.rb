class Api::V1::ProfileController < ApplicationController
  before_action :set_profile, only: [ :show, :update ]

  def show
    render json: @profile.as_json(
      methods: :age
    )
  end

  def update
    @profile.update profile_params
    render json: @profile
  end

  private

  def set_profile
    @profile = Current.user.profile
  end

  def profile_params
    params.expect(profile: [ :first_name, :last_name, :date_of_birth ])
  end
end

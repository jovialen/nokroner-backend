class PagesController < ApplicationController
  allow_unauthenticated_access only: [ :home, :login, :register ]
  before_action :resume_session, only: [ :home ]

  include ActionController::Helpers
  include ActionController::Rendering
  include ActionController::ImplicitRender
  include ActionView::Layouts
  include ActionController::Flash
  include Rails.application.routes.url_helpers

  append_view_path Rails.root.join("app", "views")
  helper_method :login_path, :home_path, :docs_path, :register_path, :api_v1_login_path, :api_v1_logout_path, :api_v1_register_path
  layout "application"

  def home
  end

  def login
  end

  def register
  end
end

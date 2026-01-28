class ApplicationController < ActionController::Base
  include PlanEnforceable

  before_action :authenticate_user!
end

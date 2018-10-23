class RobotController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:velocity, :position, :acceleration]

  def velocity
    Config.linear_velocity = params[:velocity].to_f unless params[:velocity].nil?
    Layer.from_redis(params[:layer]).build_trajectories unless params[:layer].nil?
    head(:ok)
  end

  def acceleration
    Config.linear_acceleration = params[:acceleration].to_f unless params[:acceleration].nil?
    Layer.from_redis(params[:layer]).build_trajectories unless params[:layer].nil?
    head(:ok)
  end

  def position
  end
end

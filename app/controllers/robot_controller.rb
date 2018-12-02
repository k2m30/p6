class RobotController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:velocity, :position, :acceleration, :stop, :run]

  def velocity
    Config.linear_velocity = params[:velocity].to_f unless params[:velocity].nil?
    Layer.from_redis(params[:layer]).build_trajectories unless params[:layer].blank?
    head(:ok)
  end

  def acceleration
    Config.linear_acceleration = params[:acceleration].to_f unless params[:acceleration].nil?
    Layer.from_redis(params[:layer]).build_trajectories unless params[:layer].blank?
    head(:ok)
  end

  def position
  end

  def run
    Redis.new.set 'running', true
    head(:ok)
  end

  def running
    render plain: Redis.new.get('running') || false
  end

  def stop
    Redis.new.del'running'
    head(:ok)
  end
end

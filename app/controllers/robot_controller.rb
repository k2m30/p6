class RobotController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:velocity, :acceleration, :stop, :run, :next_trajectory, :prev_trajectory, :reset_trajectory]

  def velocity
    Config.linear_velocity = params[:velocity].to_f unless params[:velocity].nil?
    Layer.build(params[:layer]) unless params[:layer].blank?
    head(:ok)
  end

  def acceleration
    Config.linear_acceleration = params[:acceleration].to_f unless params[:acceleration].nil?
    Layer.build(params[:layer]) unless params[:layer].blank?
    head(:ok)
  end

  def state
    render json: helpers.get_state
  end

  def run
    Redis.new.publish 'paint', ''
    head(:ok)
  end

  def next_trajectory
    render plain: Trajectory.next
  end

  def reset_trajectory
    render plain: Trajectory.reset
  end

  def prev_trajectory
    render plain: Trajectory.prev
  end

  def running
    render plain: Redis.new.get('running') || false
  end

  def stop
    Redis.new.del 'running'
    head(:ok)
  end
end

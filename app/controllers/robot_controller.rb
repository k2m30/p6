class RobotController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:velocity, :position, :acceleration, :stop, :run, :next_trajectory, :prev_trajectory]

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
    redis = Redis.new
    state = JSON[redis.get(:state) || {left: 0, right: 0}.to_json, symbolize_names: true]
    pd = Math::PI * Config.motor_pulley_diameter / 360.0
    point = Point.new(state[:left] * pd , state[:right] * pd).to_decart(Config.width, Config.dm, Config.dy) rescue Point.new(0,0)
    render json: state.merge(x: point&.x, y: point&.y, running: redis.get('running') || false)
  end

  def run
    Redis.new.set 'running', true
    head(:ok)
  end

  def next_trajectory
    render plain: (Config.start_from += 1).to_i
  end

  def prev_trajectory
    start_from = Config.start_from.to_i
    if start_from > 0
      start_from -= 1
      Config.start_from -= 1
    end
    render plain: start_from
  end

  def running
    render plain: Redis.new.get('running') || false
  end

  def stop
    Redis.new.del 'running'
    head(:ok)
  end
end

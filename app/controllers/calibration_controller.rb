class CalibrationController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:manual]
  before_action :set_redis

  def index
    state = helpers.get_state
    @left_mm = state[:left_mm]
    @right_mm = state[:right_mm]
  end

  def manual
    @redis.publish('commands', {command: 'manual', motor: params[:motor], direction: params[:direction], distance: params[:distance]}.to_json)
    head :ok
  end

  def move
    @redis.publish('commands', {command: 'move', x: params[:x], y: params[:y]}.to_json)
    redirect_to calibrate_path
  end

  def adjust
    motor = params[:left].present? ? 'left' : 'right'
    mm = params[motor].to_f
    actual_position = Point.new(mm, mm).get_motors_deg.x
    @redis.publish('commands', {command: 'correct', motor: motor, actual_position: actual_position}.to_json)
    redirect_to calibrate_path
  end

  def set_redis
    @redis = Redis.new
  end
end
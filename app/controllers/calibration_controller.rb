class CalibrationController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:manual]
  before_action :set_redis
  def index
    @correction_left = Config.correction_left
    @correction_right = Config.correction_right
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
    state = helpers.get_state
    point = Point.new(state[:left_deg], state[:right_deg]).get_belts_length(correction_left: 0, correction_right: 0)
    params[:correction_left].present? ? Config.correction_left = Float(params[:correction_left]) - point.x : Config.correction_right = Float(params[:correction_right]) - point.y
    redirect_to calibrate_path
  end

  def set_redis
    @redis = Redis.new
  end
end
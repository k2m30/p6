class CalibrationController < ApplicationController
  def index
    @correction_left = Config.correction_left
    @correction_right = Config.correction_right
  end

  def manual
    redirect_to calibrate_path
  end

  def move
    redirect_to calibrate_path
  end

  def adjust
    params[:correction_left].nil? ? Config.correction_right = params[:correction_right] : Config.correction_left = params[:correction_left]
    redirect_to calibrate_path
  end
end
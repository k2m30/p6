class SettingsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:update]
  def index
    @keys = Config.keys
  end

  def update
    Config.send(params[:key]+'=', params[:value])
    head :ok
  end
end
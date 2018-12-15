class PagesController < ApplicationController
  def main
    # @image = SVG.new('flying.svg')
    path = Rails.root.join('public')
    @image = SVG.new(Config.image_name, path)
    @images = Dir.glob(path.join('*.svg')).map {|f| File.basename f}
    name = params[:layer]
    @layer = if name.nil?
               @image.xml.to_xml
             elsif Redis.new.get(name)
               Layer.from_redis(name).to_svg(@image.header)
             else
               @image.get_layer(name).to_svg(@image.header)
             end
    @velocity = Config.simulation_velocity
  end

  def build
    layer_name = params[:layer]
    unless layer_name.nil?
      Layer.build(layer_name)
    end
    redirect_to root_url(layer: layer_name)
  end

  def image
    Config.image_name = params[:image] || 'calibrate.svg'
    redirect_to root_url
  end

  def trajectory
    timestamp = Time.now.to_i
    file_name = Rails.root.join('tmp', "#{file_name}_#{params[:id]}_#{timestamp}.html")
    Plot.trajectory n: params[:id], file_name: file_name
    render file: file_name, layout: nil
  end
end

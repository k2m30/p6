class PagesController < ApplicationController
  def main
    # @image = SVG.new('flying.svg')
    path = Rails.root.join('public')
    @image = SVG.new(Config.image_name, path)
    @images = Dir.glob(path.join('*.svg')).map {|f| File.basename f}
    # @image = SVG.new('calibrate.svg')
    @layer = if params[:layer].nil?
               @image.xml.to_xml
             else
               @image.get_layer(params[:layer]).to_svg(@image.header)
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
end

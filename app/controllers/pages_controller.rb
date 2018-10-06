class PagesController < ApplicationController
  def main
    # @image = SVG.new('flying.svg')
    # @image = SVG.new('risovaka007_003.svg')
    @image = SVG.new('calibrate.svg')
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
end

class PagesController < ApplicationController
  def main
    # @image = Image.new('flying.svg')
    @image = SVG.new('risovaka007_003.svg')
    @layer = if params[:layer].nil?
               @image.xml.to_xml
             else
               @image.layers[params[:layer]].to_svg(@image.header)
             end
  end

  def build
    layer_name = params[:layer]
    unless layer_name.nil?
      layer = Layer.build(layer_name)
    end
    render plain: layer.to_xml
  end
end

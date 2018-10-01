class PagesController < ApplicationController
  def main
    # @image = Image.new('flying.svg')
    @image = SVG.new('risovaka007_003.svg')
    @layer = params[:layer].nil? ? @image.xml.to_xml : @image.layers[params[:layer]].to_svg(@image.header)
  end

  def build
    layer = params[:layer]
    unless layer.nil?
      Layer.build(layer)
    end
    render plain: Redis.new.get(:splitted)
  end
end

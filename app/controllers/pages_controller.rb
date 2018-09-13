class PagesController < ApplicationController
  def main
    @image = Image.new('flying.svg')
    # @image = Image.new('risovaka007_003.svg')
    layer = params[:layer]
    if layer.nil?
      @svg = @image.name
    else
      @svg = @image.svg.build_svg(layer)

    end
  end
end

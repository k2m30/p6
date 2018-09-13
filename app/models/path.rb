class Path
  attr_reader :d, :elements, :xml, :color, :width, :opacity
  def initialize(path)
    @xml = path
    @d = path.attributes['d']
    @color = path.attributes['stroke']
    @width = path.attributes['stroke-width']
    @opacity = path.attributes['fill-opacity']
  end
end
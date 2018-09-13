class Path
  attr_reader :d, :elements, :xml, :color, :width
  def initialize(path)
    @xml = path
    @d = path.attributes['d']
    @color = path.attributes['stroke']
    @width = path.attributes['stroke-width']
  end
end
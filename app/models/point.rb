class Point
  attr_accessor :x, :y

  def initialize(x, y)
    raise "Wrong inputs #{x}, #{y}" if x.nil? or y.nil?
    @x = x.to_f
    @y = y.to_f
  end

  def to_s
    "#{@x},#{@y}"
  end

  def inspect
    to_s
  end

  def inverse(width, dm, dy)
    lx = Math.sqrt((x - dm / 2) ** 2 + (y - dy) ** 2)
    ly = Math.sqrt((width - x - dm / 2) ** 2 + (y - dy) ** 2)
    Point.new lx.round(2), ly.round(2)
  end

  def to_decart(width, dm, dy)
    mx = (@x ** 2 - @y ** 2 + (width - dm) ** 2) / 2 / (width - dm)
    xx = mx + dm / 2
    yy = Math.sqrt(@x ** 2 - mx ** 2) + dy

    Point.new xx.round(2), yy.round(2)
  end

  def self.distance(p1, p2)
    Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2)
  end
end
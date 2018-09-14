class Point
  attr_accessor :x, :y

  def initialize(x, y)
    raise StandardError.new("Wrong inputs #{x}, #{y}") if x.nil? or y.nil?
    @x=x.to_f
    @y=y.to_f
  end

  def to_s
    "#{@x},#{@y}"
  end

  def to_triangle(width)
    x = self.x
    y = self.y
    lx = Math.sqrt(x*x + y*y)

    x = self.x
    y = self.y
    ly = Math.sqrt((width-x)*(width-x) + y*y)

    Point.new lx.round(2), ly.round(2)
  end

  def to_decart(width)
    lx = self.x
    ly = self.y

    x = (lx*lx - ly*ly + width*width)/(2*width)
    y = Math.sqrt(lx*lx - x*x)

    Point.new x.round(2), y.round(2)
  end

  def self.distance(p1, p2)
    Math.sqrt((p1.x - p2.x)**2 + (p1.y - p2.y)**2)
  end
end
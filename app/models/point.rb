class Point
  attr_accessor :x, :y

  def initialize(x, y)
    fail "Wrong inputs #{x}, #{y}" if x.nil? or y.nil?
    @x = Float x
    @y = Float y
  end

  def to_s
    "#{@x.round(2)},#{@y.round(2)}"
  end

  def inspect
    to_s
  end

  def inverse(width = Config.canvas_size_x, dm = Config.dm, dy = Config.dy)
    lx = Math.sqrt((x - dm / 2.0) ** 2 + (y - dy) ** 2)
    ly = Math.sqrt((width - x - dm / 2.0) ** 2 + (y - dy) ** 2)
    Point.new lx, ly
  end

  def to_decart(width = Config.canvas_size_x, dm = Config.dm, dy = Config.dy)
    mx = (@x ** 2 - @y ** 2 + (width - dm) ** 2) / 2.0 / (width - dm)
    xx = mx + dm / 2.0
    yy = Math.sqrt(@x ** 2 - mx ** 2) + dy

    Point.new xx, yy
  end

  def self.distance(p1, p2)
    Math.sqrt((p1.x - p2.x) ** 2 + (p1.y - p2.y) ** 2)
  end

  def ==(point)
    x == point.x and y == point.y
  end

  def get_motors_deg(diameter = Config.motor_pulley_diameter)
    [x * 360.0 / (diameter * Math::PI), y * 360.0 / (diameter * Math::PI)]
  end
end
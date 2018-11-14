class Element
  attr_accessor :start_point, :end_point
  attr_reader :command_code

  def initialize(points)
    raise StandardError.new('Empty points for element') if points.empty?
    @start_point = points.first
    @end_point = points.last
  end

  def self.get_end_point(d)
    m = /(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+) ?$/.match d
    Point.new(m[:x], m[:y])
  end

  def self.from_str(start_point, d)
    new([start_point, get_end_point(d)])
  end

  def self.from_json(json)
    start_point = Point.new(json['start_point']['x'], json['start_point']['y'])
    end_point = Point.new(json['end_point']['x'], json['end_point']['y'])
    case json['command_code']
    when 'L'
      Line.new([start_point, end_point])
    when 'M'
      MoveTo.new([start_point, end_point])
    when 'C'
      control_point_1 = Point.new(json['control_point_1']['x'], json['control_point_1']['y'])
      control_point_2 = Point.new(json['control_point_2']['x'], json['control_point_2']['y'])
      CubicCurve.new([start_point, control_point_1, control_point_2, end_point])
    else
      fail "Unrecognized code #{json['command_code']}"
    end
  end

  def inverse(width, dm, dy)
    inverse = self.deep_dup
    inverse.start_point = inverse.start_point.inverse(width, dm, dy)
    inverse.end_point = inverse.end_point.inverse(width, dm, dy)
    inverse
  end

  def to_s
    "#{@command_code}#{@end_point} "
  end

  def inspect
    to_s
  end

  def length
    fail 'cannot calculate length for curve' if self.is_a? CubicCurve
    Math.sqrt((@start_point.x - @end_point.x) ** 2 + (@start_point.y - @end_point.y) ** 2)
  end

end
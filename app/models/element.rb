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

  def self.from_str(start_point, d )
    new([start_point, get_end_point(d)])
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

  #will not work for Curves
  def length
    @length ||= Math.sqrt((@start_point.x - @end_point.x) ** 2 + (@start_point.y - @end_point.y) ** 2)
  end

end
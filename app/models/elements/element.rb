class Element
  attr_accessor :start_point, :end_point
  attr_reader :command_code
  def initialize(d, start_point = nil)
    @start_point = start_point
    @end_point = get_end_point(d)
  end

  def get_end_point(d)
    m = /(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+) ?$/.match d
    Point.new(m[:x], m[:y])
  end

  def inverse(width, dm, dy)
    inverse = self.deep_dup
    inverse.start_point = inverse.start_point.inverse(width, dm, dy)
    inverse.end_point = inverse.end_point.inverse(width, dm, dy)
    inverse
  end

  def to_s
    "#{@command_code}#{@end_point}"
  end
end
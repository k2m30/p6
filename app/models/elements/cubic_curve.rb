require_relative 'element'
class CubicCurve < Element
  attr_reader :control_point_1, :control_point_2
  def initialize(d, start_point = nil)
    super
    @command_code = 'C'
    get_control_points
  end

  def get_control_points
    m = / ?\w(?<x1>[\d.-]+) ?, ?(?<y1>[\d.-]+) (?<x2>[\d.-]+) ?, ?(?<y2>[\d.-]+)/.match @d
    @control_point_1 = Point.new(m[:x1], m[:y1])
    @control_point_2 = Point.new(m[:x2], m[:y2])
  end

  def to_s
    "#{@command_code}#{@control_point_1} #{@control_point_2} #{@end_point} "
  end
end
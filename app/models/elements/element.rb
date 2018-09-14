class Element
  attr_reader :d, :start_point, :end_point, :command_code
  def initialize(d, start_point = nil)
    @d = d
    @start_point = start_point
    @end_point = get_end_point
  end

  def get_end_point
    m = /(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+) ?$/.match @d
    Point.new(m[:x], m[:y])
  end
end
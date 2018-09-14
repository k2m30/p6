class Element
  attr_reader :start_point, :end_point, :command_code
  def initialize(d, start_point = nil)
    @start_point = start_point
    @end_point = get_end_point(d)
  end

  def get_end_point(d)
    m = /(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+) ?$/.match d
    Point.new(m[:x], m[:y])
  end
end
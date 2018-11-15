require_relative 'element'
class Line < Element
  def initialize(points)
    @command_code = 'L'
    super
  end

  def reverse!
    tmp = @start_point
    @start_point = @end_point
    @end_point = tmp
    self
  end

  def split(size)
    n = (length / size).ceil
    dx = (@end_point.x - @start_point.x) / n
    dy = (@end_point.y - @start_point.y) / n

    result = []
    sp = @start_point
    n.times do |i|
      point = Point.new(@start_point.x + dx * (i + 1), @start_point.y + dy * (i + 1))
      dl = Line.new([sp, point])
      fail 'Wrong line split' if dl.length > size
      result << dl
      sp = dl.end_point
    end
    result
  end
end
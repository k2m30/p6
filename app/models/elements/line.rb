require_relative 'element'
class Line < Element
  def initialize(d, start_point = nil)
    @command_code = 'L'
    super
  end

  def to_s
    "#{@command_code}#{@end_point} "
  end

  def reverse!
    tmp = @start_point
    @start_point = @end_point
    @end_point = tmp
    self
  end

  def split(size)
    n = (length / (size+1)).ceil
    dx = (@end_point.x-@start_point.x)/n
    dy = (@end_point.y-@start_point.y)/n

    result = []
    sp = @start_point
    n.times do |i|
      dl = Line.new("L#{(@start_point.x + dx*(i+1)).round(2)},#{(@start_point.y + dy*(i+1)).round(2)}", sp)
      result << dl
      sp = dl.end_point
    end
    result
  end

  def length
    Math.sqrt((@start_point.x-@end_point.x)**2 + (@start_point.y-@end_point.y)**2)
  end

end
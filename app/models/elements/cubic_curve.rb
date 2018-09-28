require_relative 'element'
class CubicCurve < Element
  attr_reader :control_point_1, :control_point_2

  def initialize(d, start_point = nil)
    super
    @command_code = 'C'
    @control_point_1, @control_point_2 = get_control_points(d)
  end

  def get_control_points(d)
    m = / ?\w(?<x1>[\d.-]+) ?, ?(?<y1>[\d.-]+) (?<x2>[\d.-]+) ?, ?(?<y2>[\d.-]+)/.match d
    return Point.new(m[:x1], m[:y1]), Point.new(m[:x2], m[:y2])
  end

  def to_s
    "#{@command_code}#{@control_point_1} #{@control_point_2} #{@end_point} "
  end

  def reverse!
    tmp = @start_point
    @start_point = @end_point
    @end_point = tmp

    tmp_c = @control_point_1
    @control_point_1 = @control_point_2
    @control_point_2 = tmp_c

    self
  end

  def split(size, last_curve_point = nil)
    n = 4 #start number of pieces value

    x0 = @start_point.x
    y0 = @start_point.y

    if @control_point_2
      x1 = @control_point_1.x
      y1 = @control_point_1.y
    else
      x1 = 2 * @start_point.x - last_curve_point.x
      y1 = 2 * @start_point.y - last_curve_point.y
    end

    x2 = @control_point_2.x
    y2 = @control_point_2.y

    x3 = @end_point.x
    y3 = @end_point.y

    #if curve is too small - just change it to line
    if (length(x0, y0, x1, y1) < size) && (length(x1, y1, x2, y2) < size) &&
        (length(x2, y2, x3, y3) < size) && (length(x0, y0, x3, y3) < size)
      return [Line.new("L#{x3.round(2)},#{y3.round(2)}")]
    end

    #### detecting proper differentiation value
    max_length = nil

    begin
      last_x = x0
      last_y = y0
      max_length = 0
      n = (n * 1.2).round
      dt = 1.0 / n
      t = dt

      n.times do
        x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
        y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
        length = Math.sqrt((x - last_x) * (x - last_x) + (y - last_y) * (y - last_y))
        max_length = length if length > max_length
        t += dt
        last_x = x
        last_y = y
      end
    end while max_length > size

    ####
    dt = 1.0 / n
    t = dt

    result = []
    sp = @start_point
    (n - 1).times do
      x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
      y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
      dl = Line.new("L#{x.round(2)},#{y.round(2)}", sp)
      result << dl
      sp = dl.end_point
      t += dt
    end
    t = 1
    x = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t) * x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3
    y = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t) * y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3
    result << Line.new("L#{x.round(2)},#{y.round(2)}", sp)
    result
  end

  private

  def length(x1, y1, x2, y2)
    Math.sqrt((x2-x1)**2 + (y2-y1)**2)
  end

end
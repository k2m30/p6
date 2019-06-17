require_relative 'array'
require_relative 'pvat'

class VelocitySpline
  attr_accessor :l1, :l2, :t1, :t2, :max_linear_velocity, :linear_acceleration

  STEP = 0.1

  def initialize(length:, max_linear_velocity:, linear_acceleration:, t: nil)
    @max_linear_velocity = max_linear_velocity.to_f
    @linear_acceleration = linear_acceleration.to_f
    @t1 = @max_linear_velocity / @linear_acceleration
    @l1 = @linear_acceleration * @t1 ** 2 / 2

    @l2 = length - 2 * @l1
    if @l2 <= 0
      @l1 = length / 2
      @l2 = 0.0
      @t1 = Math.sqrt(2 * @l1 / @linear_acceleration)
      @max_linear_velocity = @linear_acceleration * @t1
    end

    @t2 = @l2 / @max_linear_velocity
  end

  def l(t: nil)
    return 2 * @l1 + @l2 if t.nil?
    return 0 if t.zero?
    fail 'Time cannot be less than zero' if t < 0
    if t <= @t1
      @linear_acceleration * t ** 2 / 2
    elsif t > @t1 and t <= @t1 + @t2
      @l1 + (t - @t1) * @max_linear_velocity
    elsif t <= 2 * @t1 + @t2
      @l1 + @l2 + @max_linear_velocity * (t - @t1 - @t2) - @linear_acceleration * (t - @t1 - @t2) ** 2 / 2
    else
      fail 'Time cannot be greater than expected'
    end
  end

  def v(t:)
    return 0 if t.zero? or t == 2 * @t1 + @t2
    fail 'Time cannot be less than zero' if t < 0
    if t <= @t1
      @linear_acceleration * t
    elsif t > @t1 and t <= @t1 + @t2
      @max_linear_velocity
    elsif t <= 2 * @t1 + @t2
      @max_linear_velocity - @linear_acceleration * (t - @t1 - @t2)
    else
      fail 'Time cannot be greater than expected'
    end
  end

  def a(t:)
    fail 'Time cannot be less than zero' if t < 0
    if t <= @t1
      @linear_acceleration
    elsif t > @t1 and t <= @t1 + @t2
      0
    elsif t <= 2 * @t1 + @t2
      -@linear_acceleration
    else
      fail 'Time cannot be greater than expected'
    end
  end


  def time_at(s:)
    return 0 if s.zero?
    return 2 * @t1 + @t2 if s >= 2 * @l1 + @l2 and (s - (2 * @l1 + @l2)) < 0.00001
    fail 'S cannot be less than zero' if s < 0

    if s <= @l1
      Math.sqrt(2 * s / @linear_acceleration)
    elsif s > @l1 and s <= @l1 + @l2
      @t1 + (s - @l1) / @max_linear_velocity
    elsif s <= 2 * @l1 + @l2
      v = Math.sqrt(@max_linear_velocity ** 2 - 2 * @linear_acceleration * (s - @l1 - @l2))
      dt = (@max_linear_velocity - v) / @linear_acceleration
      @t1 + @t2 + dt
    else
      fail 'Spline length cannot be greater than expected'
    end
  end

  def pvat_points(dt: STEP)
    @pvat_points = []
    diffs = time_range(dt: dt).diff
    time_range(dt: dt).each_with_index do |t, i|
      v = v(t: t)
      p = l(t: t)
      a = a(t: t)
      @pvat_points << PVAT.new(p, v, a, diffs[i] * 1000.0)
    end
    @pvat_points
  end

  def time_range(dt: STEP)
    range = (0..(2 * @t1 + @t2)).step(dt).to_a
    range[-1] = 2 * @t1 + @t2
    range
  end

  def plot(file_name:)
    @pvat_points ||= pvat_points
    Plot.html(x: time_range, y: @pvat_points.map(&:p), file_name: file_name.sub('.html', '_p.html'))
    Plot.html(x: time_range, y: @pvat_points.map(&:v), file_name: file_name.sub('.html', '_v.html'))
    Plot.html(x: time_range, y: @pvat_points.map(&:a), file_name: file_name.sub('.html', '_a.html'))

    positions = @pvat_points.map(&:p)
    time_ats = []
    positions.each do |p|
      time_ats << time_at(s: p)
    end
    Plot.html(x: positions, y: time_ats, file_name: file_name.sub('.html', '_time_at.html'))
  end
end

class VelocitySpline < Spliner::Spliner

  attr_accessor :time_points, :velocity_points, :l1, :l2
  STEP = 0.0001

  def initialize(time_points, velocity_points)
    @time_points = time_points
    @velocity_points = velocity_points
    @max_linear_velocity = velocity_points[3]
    @t1 = time_points[3]
    @t2 = time_points[-4]

    super

    @t_array = ((0.0..@t1).step(STEP).to_a + [@t1] + (@t2..range.max).step(STEP).to_a + [range.max]).uniq
    @v_array = get(@t_array)
    @l1 = self.l(t: @t1)
    @l2 = @max_linear_velocity * (@t2 - @t1)
  end

  def self.create(length:, max_linear_velocity:, linear_acceleration:)
    t1 = max_linear_velocity / linear_acceleration
    l1 = linear_acceleration * t1 ** 2 / 2

    t3 = max_linear_velocity / linear_acceleration
    l3 = linear_acceleration * t3 ** 2 / 2

    l2 = length - l1 - l3
    if l2 <= 0
      l1 = length / 2
      l2 = 0.0
      t1 = Math.sqrt(2 * l1 / linear_acceleration)
      max_linear_velocity = linear_acceleration * t1
    end

    t2 = l2 / max_linear_velocity

    n = 20.0
    dt = t1 / 100
    dl = [1.0, length / 10.0].min
    k = 0
    smooth = 6.0
    begin
      time = [0,
              t1 / smooth,
              t1 * (smooth - 1) / smooth,
              (0..n).to_a.map {|i| t1 + t2 / n * i}.uniq,
              2 * t1 + t2 - t1 * (smooth - 1) / smooth,
              2 * t1 + t2 - t1 / smooth,
              2 * t1 + t2].flatten
      velocity = [0.0,
                  max_linear_velocity / smooth ** 2,
                  max_linear_velocity * (smooth ** 2 - 1) / smooth ** 2,
                  [max_linear_velocity] * (time.size - 6),
                  max_linear_velocity * (smooth ** 2 - 1) / smooth ** 2,
                  max_linear_velocity / smooth ** 2,
                  0.0].flatten
      tmp_spline = new(time, velocity)

      puts tmp_spline.l
      sign = tmp_spline.l - length > 0 ? -1 : 1
      if t2.zero?
        t1 += dt * sign
      else
        t1 -= dt * sign
        t2 += 2 * dt * sign
      end
      k += 1
      break if k > 100
    end while (tmp_spline.l - length).abs > dl
    tmp_spline
  end

  def l(t: nil)
    t ||= range.max
    @v_array.zip(@t_array).each_cons(2).map do |prev, curr|
      v_prev = prev.first.abs
      t_prev = prev.last

      v_curr = curr.first.abs
      t_curr = curr.last

      next if t_curr >= t
      (v_prev + v_curr) / 2 * (t_curr - t_prev)
    end.compact.reduce(&:+)
  end

  def plot(file_name:)
    Plot.html(x: @t_array, y: @v_array, file_name: file_name.sub('.html', '_v.html'))
    Plot.html(x: @t_array, y: a_array, file_name: file_name.sub('.html', '_a.html'))
  end

  def a_array
    @v_array.zip(@t_array).each_cons(2).map do |prev, curr|
      v_prev = prev.first
      t_prev = prev.last

      v_curr = curr.first
      t_curr = curr.last

      (v_curr - v_prev) / (t_curr - t_prev)
    end
  end

  def time_at(s:)
    return 0 if s.zero?
    if s >= @l1 and s <= @l1 + @l2
      return @t1 + (s - @l1) / @max_linear_velocity
    end
    current_l = 0
    @v_array.zip(@t_array).each_cons(2).map do |prev, curr|
      v_prev = prev.first.abs
      t_prev = prev.last

      v_curr = curr.first.abs
      t_curr = curr.last

      current_l += (v_prev + v_curr) / 2 * (t_curr - t_prev)
      return t_curr if current_l >= s
    end
    @t_array.last
  end

end
require_relative 'array'

class VelocitySpline < Spliner::Spliner

  attr_accessor :time_points, :velocity_points, :pvt_points, :l1, :l2
  STEP = 0.01

  def initialize(time_points, velocity_points, length)
    @time_points = time_points
    @velocity_points = velocity_points
    @max_linear_velocity = velocity_points[3]
    @t1 = time_points[3]
    @t2 = time_points[-4]
    @length = length

    super(time_points, velocity_points)

    @t_array = (0..range.max).step(STEP).to_a
    @v_array = get(@t_array)
    calculate_s
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
      tmp_spline = new(time, velocity, length)

      # puts "#{[tmp_spline.l, length]}"
      l_diff = tmp_spline.l - length
      sign = l_diff > 0 ? 1 : -1
      if t2.zero?
        t1 -= dt * sign
      else
        t2 -= l_diff / max_linear_velocity
      end
      k += 1
      if k > 100
        fail 'Wrong velocity spline calculation'
        # break
      end
    end while (tmp_spline.l - length).abs > dl
    tmp_spline
  end

  def l(t: nil)
    return @p_array.last if t.nil?
    return 0 if t.zero?
    point = @pvt_points.select {|pvt| pvt[2] >= t}.first
    dt = t - point[2]
    ds = point[1] * dt
    point[0] + ds #position
  end

  def time_at(s:)
    return 0 if s.zero?
    return @t_array.last if s == @length
    point = @pvt_points.select {|pvt| pvt[0] >= s}.first
    ds = s - point[0]
    dt = ds / point[1]
    point[2] + dt #time
  end


  def a_array
    @v_array.diff(STEP)
  end

  def calculate_s(dt: STEP)
    unless dt == STEP
      @t_array = (0..range.max).step(dt)
      @v_array = get(@t_array)
    end
    @p_array = @v_array.map {|v| v * dt}.cumsum
    @pvt_points = @p_array.zip(@v_array, @t_array)
  end

  def plot(file_name:)
    Plot.html(x: @t_array, y: @v_array, file_name: file_name.sub('.html', '_v.html'))
    Plot.html(x: @t_array, y: a_array, file_name: file_name.sub('.html', '_a.html'))
  end
end
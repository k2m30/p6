require 'csv'
require_relative 'array'

class Trajectory
  attr_accessor :left_motor_points, :right_motor_points, :id, :d

  def initialize(left_motor_points, right_motor_points, id, d = nil)
    fail unless left_motor_points.is_a? Array and right_motor_points.is_a? Array
    fail if left_motor_points.size != right_motor_points.size

    @left_motor_points = left_motor_points || []
    @right_motor_points = right_motor_points || []
    @id = id
    @d = d
  end

  def self.build(spath, tpath, id)
    fail if spath.elements.size != tpath.elements.size

    max_linear_velocity = Config.linear_velocity
    linear_acceleration = Config.linear_acceleration

    @data = []
    return Trajectory.new([], [], id) if spath.length.zero?

    velocity_spline = VelocitySpline.new(length: spath.length,
                                         linear_acceleration: linear_acceleration,
                                         max_linear_velocity: max_linear_velocity)

    tpath.elements[1..-1].each_with_index do |curr, i|
      r = Row.new
      r.dl = spath.elements[i + 1].length

      start_point_deg = curr.start_point.get_motors_deg
      r.start_left_deg = start_point_deg.x
      r.start_right_deg = start_point_deg.y

      end_point_deg = curr.end_point.get_motors_deg
      r.end_left_deg = end_point_deg.x
      r.end_right_deg = end_point_deg.y

      prev_l = i.zero? ? 0 : @data[i - 1].l
      r.l = prev_l + r.dl
      r.t = velocity_spline.time_at(s: r.l).round(3)

      prev_t = i.zero? ? 0 : @data[i - 1].t
      r.dt = r.t - prev_t
      fail 'spath discretization is too small' if r.dt.zero?

      r.v_average_left = (r.end_left_deg - r.start_left_deg) / r.dt
      r.v_average_right = (r.end_right_deg - r.start_right_deg) / r.dt

      @data << r
    end

    @data.first.v_left = 0
    @data.first.v_right = 0

    @data.each_cons(2) do |r, r_next|
      r_next.v_left = (r.v_average_left + r_next.v_average_left) / 2
      r_next.v_right = (r.v_average_right + r_next.v_average_right) / 2
    end

    dts = [0] + @data.map(&:dt)

    r = Row.new
    r.v_left = 0
    r.v_right = 0
    r.a_left = 0
    r.a_right = 0
    last_point = tpath.elements.last.end_point.get_motors_deg
    r.start_left_deg = last_point.x
    r.start_right_deg = last_point.y

    @data.push r

    @data.each_with_index {|r, i| r.dt = dts[i]}

    @data.each_cons(3) do |first, second, third|
      if (first.start_left_deg < second.start_left_deg and third.start_left_deg < second.start_left_deg) or (first.start_left_deg > second.start_left_deg and third.start_left_deg > second.start_left_deg)
        second.v_left = 0
      end

      if (first.start_right_deg < second.start_right_deg and third.start_right_deg < second.start_right_deg) or (first.start_right_deg > second.start_right_deg and third.start_right_deg > second.start_right_deg)
        second.v_right = 0
      end
    end

    @data.each_cons(2) do |r, r_next|
      # r.a_left = 0
      # r.a_right = 0
      r.a_left = (r_next.v_left - r.v_left) / r_next.dt
      r.a_right = (r_next.v_right - r.v_right) / r_next.dt
    end


    @data.each_cons(2) do |first, second|
      if (second.start_left_deg - first.start_left_deg) > 0
        if second.v_left < 0
          fail 'Over zero velocity move failed'
        end
      else
        if second.v_left > 0
          fail 'Over zero velocity move failed'
        end
      end

      if (second.start_right_deg - first.start_right_deg) > 0
        if second.v_right < 0
          fail 'Over zero velocity move failed'
        end
      else
        if second.v_right > 0
          fail 'Over zero velocity move failed'
        end
      end
    end

    @left_motor_points = []
    @right_motor_points = []

    # calculate_move_to_points(tpath)

    @data.each do |r|
      dt = (r.dt * 1000).to_i
      @left_motor_points.push PVAT.new(r.start_left_deg, r.v_left, 1E-16, dt, true)
      @right_motor_points.push PVAT.new(r.start_right_deg, r.v_right, 1E-16, dt, true)
    end

    Trajectory.new @left_motor_points, @right_motor_points, id, spath.d
  end

  def self.calculate_move_to_points(tpath)
    angular_velocity = Config.max_angular_velocity
    angular_acceleration = Config.max_angular_acceleration

    # first add move_to commands
    point = Point.new(tpath.elements.first.start_point.x, tpath.elements.first.start_point.y).get_motors_deg
    move_to_left_deg = point.x
    move_to_right_deg = point.y

    @left_motor_points = RRServoMotor.get_move_to_points(from: move_to_left_deg, to: @data[0].left_deg, max_velocity: angular_velocity, acceleration: angular_acceleration)
    @right_motor_points = RRServoMotor.get_move_to_points(from: move_to_right_deg, to: @data[0].right_deg, max_velocity: angular_velocity, acceleration: angular_acceleration)

    unless @left_motor_points.empty?
      fail "Wrong left motor move_to calculation ##{id}" unless @left_motor_points.first.v.zero? and @left_motor_points.last.v.zero?
    end
    unless @right_motor_points.empty?
      fail "Wrong left motor move_to calculation ##{id}" unless @right_motor_points.first.v.zero? and @right_motor_points.last.v.zero?
    end

    time_left = @left_motor_points.map(&:t).sum
    time_right = @right_motor_points.map(&:t).sum

    time_diff = time_left - time_right
    size_diff = @left_motor_points.size - @right_motor_points.size

    if size_diff.zero?
      if time_diff > 0
        @right_motor_points.last.t += time_diff.abs
      elsif time_diff < 0
        @left_motor_points.last.t += time_diff.abs
      end
    elsif size_diff > 0 #left trajectory longer
      position = @right_motor_points.last.p
      dt = (time_diff / size_diff).abs
      size_diff.times do
        @right_motor_points << PVAT.new(position, 0.0, 0.0, dt)
      end
    else #right trajectory longer
      position = @left_motor_points.last.p
      dt = (time_diff / size_diff).abs
      size_diff.abs.times do
        @left_motor_points << PVAT.new(position, 0.0, 0.0, dt)
      end
    end

    fail 'Left and right motors trajectory have different size' unless @left_motor_points.size == @right_motor_points.size
    time_left = @left_motor_points.map(&:t).sum
    time_right = @right_motor_points.map(&:t).sum

    fail "Trajectories time is different ##{id}" unless time_left.truncate(4) == time_right.truncate(4)
  end

  def self.get(id)
    from_json JSON(Redis.new.get("#{Config.version}_#{id}")) rescue nil
  end

  def empty?
    @left_motor_points.empty? and @right_motor_points.empty?
  end

  def self.from_json(json)
    left_motor_points = []
    right_motor_points = []
    json['left_motor_points'].each {|e| left_motor_points.push PVAT.new(e['p'], e['v'], e['a'], e['t'], e['paint'])}
    json['right_motor_points'].each {|e| right_motor_points.push PVAT.new(e['p'], e['v'], e['a'], e['t'], e['paint'])}
    Trajectory.new(left_motor_points, right_motor_points, json['id'], json['d'])
  end

  # def self.to_json
  #   i = 0
  #   r = Redis.new
  #   json = ''
  #   json << '['
  #   while (s = r.get("#{Config.version}_#{i}")).present?
  #     t = Trajectory.from_json(JSON.parse(s))
  #     t.id = i
  #     json << t.to_json << ','
  #     i += 1
  #   end
  #   json << ']'
  #   json.sub!(/,\]$/, ']')
  #   json
  # end

  def self.to_csv(t = 0)
    trajectory = JSON.parse(self.to_json, symbolize_names: true).select {|trajectory| trajectory[:id] == t}.first
    CSV.open("./#{t}.csv", 'wb') do |csv|
      csv << %w(pl vl al pr vr ar dt)
      # csv << %w(id motor p v t)
      trajectory[:left_motor_points].zip(trajectory[:right_motor_points]).each do |point_left, point_right|
        # decart_point = Point.new(point_left[:p], point_right[:p]).get_belts_length.to_decart
        csv << [point_left[:p], point_left[:v], point_left[:a], point_right[:p], point_right[:v], point_right[:a], point_right[:t]]
      end
    end
  end

  def self.next
    (Config.start_from += 1).to_i
  end

  def self.reset
    (Config.start_from = 0).to_i
  end

  def self.prev
    start_from = Config.start_from.to_i
    if start_from > 0
      start_from -= 1
      Config.start_from -= 1
    end
    start_from
  end

  def total_time
    @right_motor_points.map(&:t).reduce(&:+)
  end

  def to_hash
    {left_motor_points: @left_motor_points.map(&:to_hash), right_motor_points: @right_motor_points.map(&:to_hash), id: id, d: d}
  end

  def size
    @left_motor_points.size #or right_motor_points
  end
end
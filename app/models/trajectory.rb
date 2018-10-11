class Trajectory
  attr_accessor :left_motor_points, :right_motor_points

  def initialize(left_motor_points, right_motor_points)
    fail unless left_motor_points.is_a? Array and right_motor_points.is_a? Array
    fail if left_motor_points.size != right_motor_points.size

    @left_motor_points = left_motor_points
    @right_motor_points = right_motor_points
  end

  def self.build(spath, tpath)
    fail if spath.elements.size != tpath.elements.size

    linear_velocity = Config.linear_velocity
    idling_velocity = Config.idling_velocity
    linear_acceleration = Config.linear_acceleration
    pulley_radius = Config.motor_pulley_diameter / 2.0

    time_points = spath.get_time_points(linear_velocity, linear_acceleration)
    v_average_points_x = []
    v_average_points_y = []

    tpath.elements.each_cons(2) do |curr_e, next_e|
      i = tpath.elements.index(curr_e)
      j = tpath.elements.index(next_e)
      dt = time_points[j] - time_points[i]
      dpx = next_e.end_point.x - curr_e.end_point.x
      dpy = next_e.end_point.y - curr_e.end_point.y
      v_average_x = dpx / dt
      v_average_y = dpy / dt
      v_average_points_x << v_average_x
      v_average_points_y << v_average_y
      p [curr_e, next_e, dpx, dpy, v_average_x, v_average_y, dt]
    end
    puts spath
    puts tpath
    puts ['llllll']

    velocity_points_x = [0, 0]
    velocity_points_y = [0, 0]

    v_average_points_x.each_cons(2) do |curr_v, next_v|
      velocity_points_x.push ((curr_v + next_v) / 2).round(2)
    end

    v_average_points_y.each_cons(2) do |curr_v, next_v|
      velocity_points_y.push ((curr_v + next_v) / 2).round(2)
    end

    velocity_points_x.push 0.0
    velocity_points_y.push 0.0

    initial_position_x = tpath.elements.first.start_point.x
    initial_position_y = tpath.elements.first.start_point.y

    # first add move_to command
    time = spath.get_idling_time(linear_acceleration, idling_velocity)
    time_points.map! {|e| e + time}
    time_points.insert(0.0, 0.0)

    position_points_x = [initial_position_x] + tpath.elements.map(&:end_point).map(&:x)
    position_points_y = [initial_position_y] + tpath.elements.map(&:end_point).map(&:y)

    left_motor_points = []
    right_motor_points = []
    time_points.each_with_index do |time, i|
      left_motor_points.push PVT.new(position_points_x[i], velocity_points_x[i] / pulley_radius, time)
      right_motor_points.push PVT.new(position_points_y[i], velocity_points_y[i] / pulley_radius, time)
    end

    Trajectory.new left_motor_points, right_motor_points
  end

  def left
    @left_motor_points.each do |point|
      point.to_s
    end
  end

  def right
    @right_motor_points.each do |point|
      point.to_s
    end
  end

  def self.from_str(left, right)
    left_motor_points = []
    right_motor_points = []
    JSON.parse(left).each {|e| left_motor_points.push PVT.from_array(e)}
    JSON.parse(right).each {|e| right_motor_points.push PVT.from_array(e)}

    Trajectory.new(left_motor_points, right_motor_points)
  end
end

class PVT
  attr_accessor :p, :v, :t

  def initialize(p, v, t)
    fail unless [p, v, t].all?{|e| e.is_a? Float}
    @p = p
    @v = v
    @t = t
  end

  def to_s
    "[#{@p}, #{@v}, #{@t}] "
  end

  def inspect
    to_s
  end

  def self.from_array(array)
    PVT.new(array[0], array[1], array[2])
  end
end
class Trajectory
  attr_accessor :left_motor_points, :right_motor_points

  def initialize(layer)
    @layer = layer
    @left_motor_points = []
    @right_motor_points = []
    build
    p ['']
  end

  def build(start_from = 0)
    size = @layer.splitted_paths.size
    raise StandardError.new('paths sizes don' 't match') unless size == @layer.tpaths.size
    v = Config.linear_velocity
    v_idling = Config.idling_velocity
    a = Config.linear_acceleration

    @t_points = []
    @left_p_points = []
    @right_p_points = []
    time = 0

    (start_from..size).to_a.each do |i|
      tpath = @layer.tpaths[i]
      spath = @layer.splitted_paths[i]

      spath.elements.size.times do |j|
        velocity = spath.elements[j].is_a?(MoveTo) ? v_idling : v
        @t_points.push spath.get_time(j, velocity, a)
      end

      j = 0
      tpath.elements.each_cons(2) do |current_element, next_element|
        dp_left_current = current_element.end_point.x - current_element.start_point.x
        dp_right_current = current_element.end_point.y - current_element.start_point.y

        dp_left_next = next_element.end_point.x - next_element.start_point.x
        dp_right_next = next_element.end_point.y - next_element.start_point.y

        t_current = @t_points[j]
        t_next = @t_points[j + 1]

        velocity_left = (dp_left_current / t_current + dp_left_next / t_next) / 2
        velocity_right = (dp_right_current / t_current + dp_right_next / t_next) / 2

        @left_motor_points.push PVT.new(current_element.end_point.x, velocity_left, @t_points[j] + time)
        @right_motor_points.push PVT.new(current_element.end_point.y, velocity_right, @t_points[j] + time)
        j += 1
      end

    end

  end

  def self.add_move_to_between_paths(pvts)
    # code here
  end
end

class PVT
  attr_accessor :p, :v, :t

  def initialize(p, v, t)
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
end
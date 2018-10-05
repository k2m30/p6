class Trajectory
  attr_accessor :left_motor_points, :right_motor_points

  def initialize(layer)
    @layer = layer
    @left_motor_points = []
    @right_motor_points = []
    build

  end

  def build(start_from = 0)
    size = @layer.splitted_paths.size
    raise StandardError.new('paths sizes don''t match') unless size == @layer.tpaths.size
    v = Config.linear_velocity
    a = Config.linear_acceleration

    @t_points = []
    @left_p_points = []
    @right_p_points = []

    (start_from..size).to_a.each do |i|
      @t_points.push @layer.splited_paths[i].get_time(i, v, a)
      @left_p_points.push @layer.tpaths[i]
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
end
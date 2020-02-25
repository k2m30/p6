require_relative 'rr_servo_motor'
require 'numo/gnuplot'
require_relative 'plot'

class RRServoMotorDummy
  attr_accessor :position

  def initialize(interface, servo_id = 123, name)
    @interface = interface
    @id = servo_id
    @position = 0
    @queue_size = 0
    @trajectory_n = 0
    @name = name
  end

  def deinitialize
  end

  def add_point(_)
    @queue_size += 1
    p [@name, @queue_size]
    @queue_size
  end

  def queue_size
    @queue_size -= 1 if @queue_size > 0
    p [@name, @queue_size]
    @queue_size
  end

  def get_errors
  end

  def calculate_time(start_position:, start_velocity:, start_acceleration: 0, start_time: 0, end_position:, end_velocity:, end_acceleration: 0, end_time: 0)
  end

  def self.get_move_to_points(from:, to:, max_velocity: 180.0, acceleration: 250.0)
  end

  def move(from: nil, to:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    from ||= to

    points = RRServoMotor.get_move_to_points(
        from: from, to: to, max_velocity: max_velocity, acceleration: acceleration
    )
    return 0 if points.empty?

    t_id = "move_#{@trajectory_n}_#{@name}"
    # t = Trajectory.new(points, points, t_id)
    # Plot.trajectory(trajectory: t, n: t_id)
    @trajectory_n += 1

    points[1..-1].each do |point|
      begin
        add_point(point)
      rescue RetError
        puts "RET_ERROR on #{@id}, move_to"
        retry
      rescue WrongTrajectoryError => e
        t = Trajectory.new(points, points, 1000)
        Plot.trajectory(trajectory: t, n: 1000)
        fail WrongTrajectoryError, e
      end
    end
    @interface.start_motion if start_immediately
    points.map(&:t).reduce(&:+)
  end

  def set_state_operational
  end

  def check_errors(ret_code)
  end

  def soft_stop
  end

  def state
  end

  def twist
  end

  def position_set_point
  end

  def velocity
  end

  def velocity=(v)
  end

  def current
  end

  def temperature
  end

  def read_param(param)
  end

  def read_cached_params
  end

  def clear_points_queue
  end

  def add_motion_point(point, velocity, acceleration, time)
  end

  def self.get_error_value(ret_code)
  end

  def self.ret_codes
  end
end
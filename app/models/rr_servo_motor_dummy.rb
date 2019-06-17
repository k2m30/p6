require_relative 'rr_servo_motor'
require 'numo/gnuplot'
require_relative 'plot'

class RRServoMotorDummy
  attr_accessor :position
  def initialize(interface, servo_id = 123)
    @interface = interface
    @id = servo_id
    @position = 0
  end

  def deinitialize
  end

  def add_point(point)
  end

  def queue_size
  end

  def get_errors
  end

  def calculate_time(start_position:, start_velocity:, start_acceleration: 0, start_time: 0, end_position:, end_velocity:, end_acceleration: 0, end_time: 0)
  end

  def self.get_move_to_points(from:, to:, max_velocity: 180.0, acceleration: 250.0)
  end

  def go_to(pos:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    points = RRServoMotor.get_move_to_points(
        from: position, to: pos, max_velocity: max_velocity, acceleration: acceleration
    )
    return 0 if points.empty?
    points[1..-1].each do |point|
      add_point(point)
    end
    @interface.start_motion if start_immediately
    @position = points.last.p
    # Plot.html(x: points.map(&:t).cumsum, y: points.map(&:p), file_name: 'position.html')
    # Plot.html(x: points.map(&:t).cumsum, y: points.map(&:v), file_name: 'velocity.html')
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
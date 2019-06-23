require 'redis'
require 'json'
require_relative 'config'
require_relative 'pvat'
require_relative 'rr_interface'
require_relative 'rr_servo_motor'
require_relative 'plot'
require 'numo/gnuplot'
require_relative 'trajectory'

class Loop
  MIN_QUEUE_SIZE = 15
  QUEUE_SIZE = 33
  # LEFT_MOTOR_ID = 32
  # RIGHT_MOTOR_ID = 36

  LEFT_MOTOR_ID = 19
  RIGHT_MOTOR_ID = 32
  #
  NO_POINTS_IN_QUEUE_LEFT = 0

  def initialize
    @redis = Redis.new
    @log_data = []
    @idling_speed = Config.max_angular_velocity
    @acceleration = Config.max_angular_acceleration

    fail 'Already running' unless @redis.get('running').nil?

    @left_motor = initialize_motor(LEFT_MOTOR_ID)
    @right_motor = initialize_motor(RIGHT_MOTOR_ID)

    @log_data = []
    @redis.set(:state, {left: @left_motor.position, right: @right_motor.position}.to_json)
    run
  rescue => e
    puts e.message
    puts e.backtrace
  ensure
    soft_stop
    turn_painting_off
    @redis.del 'running'
  end

  def move_to(point)
    @left_motor.clear_points_queue
    @right_motor.clear_points_queue
    left_point = point.x
    right_point = point.y

    tl = @left_motor.set_position(left_point, velocity: @idling_speed, acceleration: @acceleration)
    tr = @right_motor.set_position(right_point, velocity: @idling_speed, acceleration: @acceleration)
    sleep max[tl, tr] + 0.5

  end

  def initialize_motor(id)
    device = case RUBY_PLATFORM
             when 'x86_64-darwin16'
               '/dev/cu.usbmodem301'
             when 'armv7l-linux-eabihf'
               '/dev/serial/by-id/usb-Rozum_Robotics_USB-CAN_Interface_301-if00'
             else
               'unknown_os'
             end
    # @servo_interface ||= RRInterface.new(device)
    @servo_interface ||= RRInterface.new('192.168.0.50:17700')
    RRServoMotor.new(@servo_interface, id)
  end

  def run
    loop {break unless @redis.get('running').nil?}

    initial_point = Point.new(Config.initial_x, Config.initial_y).get_motors_deg
    move_to(initial_point)
    @trajectory_index = Config.start_from.to_i
    @point_index = 0

    loop do
      @trajectory = Trajectory.get @trajectory_index
      @redis.set(:current_trajectory, @trajectory_index)

      break if @trajectory.nil?

      start_point = Point.new(@trajectory.left_motor_points.first.p, @trajectory.right_motor_points.first.p)
      move_to(start_point)
      @point_index += 1
      add_points(QUEUE_SIZE)

      @servo_interface.start_motion
      turn_painting_on

      loop do
        if @redis.get('running').nil?
          soft_stop
          fail 'Stopped outside'
        end

        queue_size = @left_motor.queue_size
        break if queue_size.zero?

        if queue_size <= MIN_QUEUE_SIZE
          # @trajectory = Trajectory.get @trajectory_index
          add_points(QUEUE_SIZE)
        end
        @redis.set(:state, {left: @left_motor.position, right: @right_motor.position}.to_json)
      end
      @trajectory_index += 1
      @point_index = 0
      turn_painting_off
    end

    finalize
  end

  def finalize
    puts 'Done. Stopped'
    @trajectory = nil
    @redis.set(:current_trajectory, 0)
    @point_index = 0
    @redis.del 'running'
    @redis.set(:log, @log_data)
    puts 'Waiting for next paint task'
  end

  def add_points(queue_size)
    queue_size.times do
      @point_index += 1
      left_point = @trajectory.left_motor_points[@point_index]
      right_point = @trajectory.right_motor_points[@point_index]
      break if right_point.nil? or left_point.nil?
      @left_motor.add_point(left_point)
      @right_motor.add_point(right_point)
    end


  rescue => e
    puts e.message
    puts e.backtrace
    puts "trajectory: #{@trajectory}"
    puts "trajectory point: #{@point_index}"
    @redis.set(:current_trajectory, 0)
    soft_stop
    fail 'Cannot send point'

  end

  def soft_stop
    turn_painting_off
    @left_motor.soft_stop
    @right_motor.soft_stop
  end

  def turn_painting_off
    # code here
  end

  def turn_painting_on

  end

end

# Loop.new
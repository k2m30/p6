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
  LEFT_MOTOR_ID = 32
  RIGHT_MOTOR_ID = 36

  # LEFT_MOTOR_ID = 19
  # RIGHT_MOTOR_ID = 32
  #
  NO_POINTS_IN_QUEUE_LEFT = 0
  @log_data = []

  def initialize
    @redis = Redis.new

    fail 'Already running' unless @redis.get('running').nil?

    @left_motor = initialize_motor(LEFT_MOTOR_ID)
    @right_motor = initialize_motor(RIGHT_MOTOR_ID)
    @left_motor.clear_points_queue
    @right_motor.clear_points_queue

    @log_data = []
    @redis.set(:state, {left: @left_motor.position, right: @right_motor.position}.to_json)
    run
  rescue => e
    puts e.message
    puts e.backtrace
  ensure
    turn_off_painting
    @redis.del 'running'
  end

  def move_to_initial_point
    # @left_motor.position = 0
    # @right_motor.position = 0
    # sleep 100
    @left_motor.clear_points_queue
    @right_motor.clear_points_queue
    point = Point.new(Config.initial_x, Config.initial_y).get_motors_deg
    left_point = point.x
    right_point = point.y
    p [left_point, right_point]

    @left_motor.go_to(pos: left_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)
    @right_motor.go_to(pos: right_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)

    @left_motor.add_motion_point(left_point, 0, 0, 1000)
    @right_motor.add_motion_point(right_point, 0, 0, 1000)

    @servo_interface.start_motion

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
    loop do
      loop {break unless @redis.get('running').nil?}

      @trajectory = Config.start_from.to_i
      move_to_initial_point

      loop do
        if @redis.get('running').nil?
          soft_stop
          fail 'Stopped outside'
        end
        queue_size = @left_motor.queue_size
        break if queue_size.zero?

        if queue_size <= MIN_QUEUE_SIZE
          add_points(QUEUE_SIZE)
        end
        @redis.set(:state, {left: @left_motor.position, right: @right_motor.position}.to_json)
      end
      puts 'Done. Stopped'
      @trajectory = 0
      @redis.set(:current_trajectory, 0)
      @trajectory_point_index = 1
      @zero_time = Time.now # Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @redis.del 'running'
      @redis.set(:log, @log_data)
      puts 'Waiting for next paint task'
    end
  end

  def add_points(queue_size)
    @log_data << [@left_motor.position, @left_motor.position_set_point, @right_motor.position, @right_motor.position_set_point, Time.now.to_f]
    begin
      path = @redis.get("#{Config.version}_#{@trajectory}")

      return if path.nil?

      path = JSON.parse path
      next_left_point = PVAT.from_json path['left_motor_points'][@trajectory_point_index]
      next_right_point = PVAT.from_json path['right_motor_points'][@trajectory_point_index]

      # puts [next_left_point, next_right_point]
      @left_motor.add_point(next_left_point)
      @right_motor.add_point(next_right_point)

      if @trajectory_point_index < path['left_motor_points'].size - 1
        @trajectory_point_index += 1
      else
        @trajectory_point_index = 1
        @trajectory += 1
        @redis.incr(:current_trajectory)
        puts @trajectory
      end

    rescue => e
      puts e.message
      puts e.backtrace
      puts @left_motor.get_errors
      puts "trajectory: #{@trajectory}"
      puts "trajectory point: #{@trajectory_point_index}"
      @redis.set(:current_trajectory, 0)
      pp [{'prev_left': PVAT.from_json(path['left_motor_points'][@trajectory_point_index - 1]), next_left: next_left_point}]
      # pp [{'prev_right': PVAT.from_json(path['right_motor_points'][@trajectory_point_index - 1]), next_left: next_right_point}]

      soft_stop
      fail 'Cannot send point'
    end until @left_motor.queue_size > queue_size
  end

  def soft_stop
    turn_off_painting # it's better to check for the 'running' key inside the painting loop
    @left_motor.soft_stop
    @right_motor.soft_stop
  end

  def turn_off_painting
    # code here
  end
end

Loop.new
require 'redis'
require 'json'
require_relative 'config'
require_relative 'pvt'
require_relative 'r_r_interface'
require_relative 'r_r_servo_motor'

class Loop
  MIN_QUEUE_SIZE = 3.0 #sec
  QUEUE_SIZE = 10.0 #sec
  LEFT_MOTOR_ID = 19
  RIGHT_MOTOR_ID = 32

  NO_POINTS_IN_QUEUE_LEFT = 0

  def initialize
    @redis = Redis.new

    fail 'Already running' unless @redis.get('running').nil?

    @point_index = 0
    @trajectory_point_index = 1
    @zero_time = Time.now # Process.clock_gettime(Process::CLOCK_MONOTONIC)

    @left_motor = initialize_motor(LEFT_MOTOR_ID)
    @right_motor = initialize_motor(RIGHT_MOTOR_ID)
    @left_motor.clear_points_queue
    @right_motor.clear_points_queue
    run
  ensure
    turn_off_painting
    @redis.del 'running'
    # @left_motor.deinitialize
    # @right_motor.deinitialize
    @servo_interface.deinitialize
  end

  def move_to_initial_point
    @left_motor.clear_points_queue
    @right_motor.clear_points_queue
    left_point = 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
    right_point = 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)

    @left_motor.go_to(pos: left_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)
    @right_motor.go_to(pos: right_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)

    @left_motor.add_motion_point(left_point, 0, 1000)
    @right_motor.add_motion_point(right_point, 0, 1000)

    @servo_interface.start_motion

  end

  def initialize_motor(id)
    @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
    RRServoMotor.new(@servo_interface, id)
  end

  def run
    data = []
    loop do
      loop {break unless @redis.get('running').nil?}

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
        data << [@left_motor.position, @right_motor.position, Time.now - @zero_time]
        p [@left_motor.current, @right_motor.current]
      end
      puts 'Done. Stopped'
      @point_index = 0
      @trajectory_point_index = 1
      @zero_time = Time.now # Process.clock_gettime(Process::CLOCK_MONOTONIC)

      @redis.del 'running'
      @redis.set(:log, data)
      puts 'Waiting for next paint task'
    end
  end

  def add_points(queue_size)
    begin
      path = @redis.get("#{Config.version}_#{@point_index}")

      return if path.nil?

      path = JSON.parse path
      next_left_point = PVT.from_json path['left_motor_points'][@trajectory_point_index]
      next_left_point.t *= 1000
      next_right_point = PVT.from_json path['right_motor_points'][@trajectory_point_index]
      next_right_point.t *= 1000


      @left_motor.add_point(next_left_point)
      @right_motor.add_point(next_right_point)

      if @trajectory_point_index < path['left_motor_points'].size - 1
        @trajectory_point_index += 1
      else
        @trajectory_point_index = 1
        @point_index += 1
      end

    rescue => e
      puts e.message
      puts e.backtrace
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
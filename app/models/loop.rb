require 'redis'
require 'json'
require_relative 'config'
require_relative 'pvat'
require_relative 'rr_interface'
require_relative 'rr_interface_dummy'
require_relative 'rr_servo_motor'
require_relative 'rr_servo_motor_dummy'
require_relative 'plot'
require 'numo/gnuplot'
require_relative 'trajectory'

class Loop
  MIN_QUEUE_SIZE = 15
  QUEUE_SIZE = 33
  LEFT_MOTOR_ID = Config.rpi? ? 19 : 32
  RIGHT_MOTOR_ID = Config.rpi? ? 32 : 36
  NO_POINTS_IN_QUEUE_LEFT = 0 # RIGHT

  def initialize
    @redis = Redis.new
    @log_data = []
    @idling_speed = Config.max_angular_velocity
    @acceleration = Config.max_angular_acceleration

    fail 'Already running' unless @redis.get('running').nil?

    @servo_interface = Config.rpi? ? RRInterface.instance : RRInterfaceDummy.instance
    @left_motor = Config.rpi? ? RRServoMotor.new(LEFT_MOTOR_ID) : RRServoMotorDummy.new(LEFT_MOTOR_ID, :left)
    @right_motor = Config.rpi? ? RRServoMotor.new(RIGHT_MOTOR_ID) : RRServoMotorDummy.new(RIGHT_MOTOR_ID, :right)

    @log_data = []
    set_status
    run
  rescue => e
    puts e.message
    puts e.backtrace
  ensure
    @redis.del 'running'
    soft_stop
    finalize
  end

  def run
    loop { break unless @redis.get('running').nil? }

    @zero_time = Time.now
    end_point = Point.new(Config.initial_x, Config.initial_y).get_motors_deg
    start_point = Config.rpi? ? nil : end_point
    move(from: start_point, to: end_point)
    @trajectory_index = Config.start_from.to_i
    @point_index = 0

    loop do
      @trajectory = Trajectory.get @trajectory_index
      @redis.set(:current_trajectory, @trajectory_index)
      Config.start_from = @trajectory_index

      break if @trajectory.empty?

      start_point = Point.new(@trajectory.left_motor_points.first.p, @trajectory.right_motor_points.first.p)
      move(from: end_point, to: start_point)
      @point_index += 1
      add_points(QUEUE_SIZE)

      @servo_interface.start_motion
      turn_painting_on

      loop do
        if @redis.get('running').nil?
          puts 'Stopped outside'
          finalize
        end

        begin
          queue_size = @left_motor.queue_size #or @right_motor.queue_size
        rescue RetError
          puts "RET_ERROR on left motor during queue size check"
          retry
        end

        break if queue_size.zero?

        if queue_size <= MIN_QUEUE_SIZE
          # @trajectory = Trajectory.get @trajectory_index
          add_points(QUEUE_SIZE)
        end
        set_status
      end
      end_point = Point.new(@trajectory.left_motor_points.last.p, @trajectory.right_motor_points.last.p)
      @trajectory_index += 1
      @point_index = 0
      turn_painting_off

    end
    @redis.set(:current_trajectory, 0)
    Config.start_from = 0
  end

  def move(from: nil, to:)
    from ||= Point.new(@left_motor.position, @right_motor.position)

    tl = @left_motor.go_to(from: from.x, to: to.x, max_velocity: @idling_speed, acceleration: @acceleration, start_immediately: false)
    tr = @right_motor.go_to(from: from.y, to: to.y, max_velocity: @idling_speed, acceleration: @acceleration, start_immediately: false)
    @servo_interface.start_motion
    t = ([tl, tr].max || 0) / 1000.0 + 0.5
    time_start = Time.now
    if Config.rpi?
      begin
        sleep 0.2
        set_status
      end while Time.now - time_start < t
    end
  end

  def finalize
    puts 'Finalizing'
    turn_painting_off
    initial_point = Point.new(Config.initial_x, Config.initial_y).get_motors_deg
    move(to: initial_point)
    puts "Done. Stopped. It took #{(Time.now - @zero_time).round(1)} secs"
    @trajectory = nil
    @point_index = 0
    @redis.del 'running'
    @redis.set(:log, @log_data)
    puts 'Waiting for next paint task'
  end

  def add_points(queue_size)
    queue_size.times do
      left_point = @trajectory.left_motor_points[@point_index]
      right_point = @trajectory.right_motor_points[@point_index]
      break if right_point.nil? or left_point.nil?
      p [@trajectory.id, @point_index, left_point, right_point]

      begin
        @left_motor.add_point(left_point)
      rescue RetError
        puts "RET_ERROR on left motor"
        retry
      end

      begin
        @right_motor.add_point(right_point)
      rescue RetError
        puts "RET_ERROR on right motor"
        retry
      end
      @point_index += 1
    end


  rescue => e
    puts e.message
    puts e.backtrace
    puts "trajectory: #{@trajectory}"
    puts "trajectory point: #{@point_index}"
    puts 'Cannot send point'
    soft_stop
    finalize

  end

  def soft_stop
    turn_painting_off
    @left_motor&.soft_stop
    @right_motor&.soft_stop
  end

  def turn_painting_off
    `gpio write 7 0` if Config.rpi?
  end

  def turn_painting_on
    `gpio write 7 1` if Config.rpi?
  end

  def set_status
    @redis.set(:state, {left: @left_motor.position, right: @right_motor.position}.to_json) rescue puts 'Unable to set status'
  end

end

# Loop.new
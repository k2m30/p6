# frozen_string_literal: true
require "redis"
require 'json'
require 'numo/gnuplot'

require_relative 'config'
require_relative 'pvat'
require_relative 'rr_interface'
require_relative 'rr_interface_dummy'
require_relative 'rr_servo_motor'
require_relative 'rr_servo_motor_dummy'
require_relative 'plot'
require_relative 'trajectory'

MIN_QUEUE_SIZE = 15
QUEUE_SIZE = 33
LEFT_MOTOR_ID = Config.rpi? ? 32 : 32 # CCW – down, positive, jet looking towards the wall
RIGHT_MOTOR_ID = Config.rpi? ? 19 : 36 # CCW – up, positive, jet looking towards the wall, to inverse

def init_system
  @redis = Redis.new
  @idling_speed = Config.max_angular_velocity
  @acceleration = Config.max_angular_acceleration

  fail 'Already running' unless @redis.get('running').nil?

  @servo_interface = Config.rpi? ? RRInterface.new : RRInterfaceDummy.new
  @left_motor = Config.rpi? ? RRServoMotor.new(@servo_interface, LEFT_MOTOR_ID) : RRServoMotorDummy.new(@servo_interface, LEFT_MOTOR_ID, :left)
  @right_motor = Config.rpi? ? RRServoMotor.new(@servo_interface, RIGHT_MOTOR_ID) : RRServoMotorDummy.new(@servo_interface, RIGHT_MOTOR_ID, :right)
  set_state
end

def wait(time_to_wait, dt = 0.2)
  time_start = Time.now
  begin
    sleep dt
    set_state
  end while Time.now - time_start < time_to_wait
end

def move(from: nil, to:)
  tl = @left_motor.move(to: to.x, max_velocity: @idling_speed, acceleration: @acceleration)
  tr = @right_motor.move(to: to.y, max_velocity: @idling_speed, acceleration: @acceleration)
  @servo_interface.start_motion
  time_to_wait = ([tl, tr].max || 0) / 1000.0 + 0.5
  wait time_to_wait
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

def set_state
  left_position = @left_motor.position
  right_position = -@right_motor.position
  @redis.set('state', {left_deg: left_position, right_deg: right_position, running: @redis.get('running') || false}.to_json) rescue puts 'Unable to set status'
end

def motors_queue_size
  @left_motor.queue_size
  @right_motor.queue_size
end

def paint_trajectory
  @servo_interface.start_motion(100)
  turn_painting_on

  begin
    if motors_queue_size <= MIN_QUEUE_SIZE
      add_points(QUEUE_SIZE)
    end
    set_state
  end while @point_index < @trajectory.size and !@redis.get('running').nil?


  fail 'Stopped outside' unless @redis.get('running')

  until motors_queue_size.zero?
    set_state
  end
  turn_painting_off
end


def add_points(queue_size)
  queue_size.times do
    left_point = @trajectory.left_motor_points[@point_index]
    right_point = @trajectory.right_motor_points[@point_index]
    break if right_point.nil? or left_point.nil?
    p [@trajectory.id, @point_index, left_point, right_point]
    @left_motor.add_point(left_point)
    @right_motor.add_point(right_point)
    @point_index += 1
  end
end


def paint
  @zero_time = Time.now
  @redis.set('running', 'true')
  @trajectory_index = Config.start_from.to_i
  @point_index = 0
  start_point = Config.start_point
  start_point.y *= -1
  move(to: start_point.get_motors_deg)

  until (@trajectory = Trajectory.get @trajectory_index).nil? # got through trajectories
    @redis.set('current_trajectory', @trajectory_index.to_s)
    Config.start_from = @trajectory_index
    unless @trajectory.empty?
      @trajectory.right_motor_points.map(&:inverse!)
      move(to: Point.new(@trajectory.left_motor_points.first.p, @trajectory.right_motor_points.first.p))

      turn_painting_on
      paint_trajectory
      turn_painting_off
    end
    @trajectory_index += 1
    @point_index = 0
  end
  start_point = Config.start_point
  start_point.y *= -1
  move(to: start_point.get_motors_deg)

  Config.start_from = 0
  puts 'Done.'
rescue => e
  puts e.message
  puts e.backtrace
ensure
  @redis.del 'running'
  turn_painting_off
  soft_stop
  finalize
end

def finalize
  puts 'Finalizing'
  turn_painting_off
  start_point = Config.start_point
  start_point.y *= -1
  move(to: start_point.get_motors_deg)

  puts "Done. Stopped. It took #{(Time.now - @zero_time).round(1)} secs"
  @trajectory = nil
  @point_index = 0
  @redis.del 'running'
  puts 'Waiting for next paint task'
end


################################################
# Main loop
################################################

trap(:INT) { puts "\nInterrupted"; exit }

redis = Redis.new
init_system

begin
  redis.subscribe(:commands) do |on|
    on.subscribe do |channel, subscriptions|
      puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
    end

    on.message do |channel, message|
      message = JSON[message, symbolize_names: true]
      case message[:command]
      when 'paint'
        paint
      when 'move'
        @zero_time = Time.now
        @redis.set('running', true)
        # @redis.publish('commands', {command: 'move', x: 300.0, y: 1400.0}.to_json)

        move(to: Point.new(message[:x], message[:y]))
        set_state
        @redis.del 'running'
        puts "Moved to #{to}. It took #{(Time.now - @zero_time).round(1)} secs"
      when 'manual'
        # @redis.publish('commands', {command: 'manual', motor: :left, direction: :down, distance: 1400.0}.to_json)
        motor = message[:motor] == 'left' ? @left_motor : @right_motor
        direction = message[:direction] == 'up' ? 1 : -1
        distance = Point.new(message[:distance].to_f, 0).get_motors_deg.x

        t = motor.move(to: motor.position + distance * direction, max_velocity: @idling_speed, acceleration: @acceleration, start_immediately: true)
        wait t
      else
        puts "##{channel}: #{message}"
      end
    end
  end
rescue Redis::BaseConnectionError => error
  puts "#{error}, retrying in 1s"
  sleep 1
  retry
end

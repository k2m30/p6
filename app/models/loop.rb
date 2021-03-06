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
LEFT_MOTOR_ID = 32 # CCW – down, positive, jet looking towards the wall
RIGHT_MOTOR_ID = 19 # CCW – up, positive, jet looking towards the wall, to inverse

def init_system
  @redis = Redis.new
  @idling_speed = Config.max_angular_velocity
  @acceleration = Config.max_angular_acceleration

  fail 'Already running' unless @redis.get('running').nil?

  if Config.connected?
    @servo_interface = RRInterface.new
    @left_motor = RRServoMotor.new(@servo_interface, LEFT_MOTOR_ID)
    @right_motor = RRServoMotor.new(@servo_interface, RIGHT_MOTOR_ID)
  else
    @servo_interface = RRInterfaceDummy.new
    @left_motor = RRServoMotorDummy.new(@servo_interface, LEFT_MOTOR_ID)
    @right_motor = RRServoMotorDummy.new(@servo_interface, RIGHT_MOTOR_ID)

    go_home
  end

  @left_motor.clear_points_queue
  @right_motor.clear_points_queue

  set_state
end

def go_home
  start_point = Config.start_point.get_motors_deg
  start_point.y *= -1
  move(to: start_point)
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
  @redis.set 'running', 'true'
  @servo_interface.start_motion
  time_to_wait = ([tl, tr].max || 0) / 1000.0 + 0.5
  wait time_to_wait if Config.connected?
  @redis.del 'running'
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
  @redis.set('state', {left_deg: left_position.round(1), right_deg: right_position.round(1), running: @redis.get('running') || false}.to_json) rescue puts 'Unable to set status'
end

def motors_queue_size
  @left_motor.queue_size
  @right_motor.queue_size
end

def paint_trajectory
  add_points(QUEUE_SIZE)
  @redis.set 'running', 'true'
  @servo_interface.start_motion
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
  @redis.del 'running'
end


def add_points(queue_size)
  queue_size.times do
    left_point = @trajectory.left_motor_points[@point_index]
    right_point = @trajectory.right_motor_points[@point_index]
    break if right_point.nil? or left_point.nil?
    @left_motor.add_point(left_point)
    @right_motor.add_point(right_point)
    @point_index += 1
  end
end


def paint
  @zero_time = Time.now
  @redis.set('running', 'true')
  set_state
  @trajectory_index = Config.start_from.to_i
  @point_index = 1
  go_home

  until (@trajectory = Trajectory.get @trajectory_index).nil? # go through trajectories
    @redis.set('current_trajectory', @trajectory_index.to_s)
    Config.start_from = @trajectory_index
    unless @trajectory.empty?
      @trajectory.right_motor_points.map(&:inverse!)
      move(to: Point.new(@trajectory.left_motor_points.first.p, @trajectory.right_motor_points.first.p))
      paint_trajectory

    end
    @trajectory_index += 1
    @point_index = 1
  end
  go_home

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
  go_home

  puts "Done. Stopped. It took #{(Time.now - @zero_time).round(1)} secs"
  @trajectory = nil
  @point_index = 1
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
      begin
        puts "##{channel}: #{message}"
        message = JSON[message, symbolize_names: true]

        case message[:command]
        when 'paint' # @redis.publish('commands', {command: 'paint'}.to_json)
          paint

        when 'status' # @redis.publish('commands', {command: 'status'}.to_json)
          p "left: #{@left_motor.position}, right: #{@right_motor.position}"

        when 'move' # @redis.publish('commands', {command: 'move', x: 300.0, y: 1400.0}.to_json)
          @zero_time = Time.now
          to = Point.new(message[:x], message[:y]).inverse.get_motors_deg
          to.y = to.y * -1
          move(to: to)
          set_state
          puts "Moved to left: #{@left_motor.position}, right: #{@right_motor.position}. It took #{(Time.now - @zero_time).round(1)} secs"

        when 'manual' # @redis.publish('commands', {command: 'manual', motor: :left, direction: :down, distance: 1400.0}.to_json)
          motor = message[:motor] == 'left' ? @left_motor : @right_motor
          direction = message[:direction] == 'up' ? -1 : 1
          direction *= -1 if motor == @right_motor
          distance = Point.new(message[:distance].to_f, 0).get_motors_deg.x

          @redis.set('running', true)
          t = motor.move(to: motor.position + distance * direction, max_velocity: @idling_speed, acceleration: @acceleration, start_immediately: true) / 1000.0
          wait t
          @redis.del 'running'
          set_state

        when 'correct' # @redis.publish('commands', {command: 'correct', motor: 'left', actual_position: 1400.0}.to_json) – degrees
          motor = message[:motor] == 'left' ? @left_motor : @right_motor
          direction = motor == @left_motor ? 1 : -1
          motor.assign_current_position_to(actual_position: message[:actual_position] * direction)
          set_state
        when 'home' # @redis.publish('commands', {command: 'home'}.to_json)
          go_home
        else
          puts "##{channel}: #{message}"
        end
      rescue => error
        @redis.del 'running'
        puts "\e[0;31m#{error.message} \e[0m\n\n"
        puts "\e[0;31m#{error.backtrace.first} \e[0m\n"
        puts "#{error.backtrace[1..4].join("\n")}, retrying in 5s"
        set_state
        sleep 5
        retry
      end
    rescue Redis::BaseConnectionError => error
      puts "#{error}, retrying in 1s"
      sleep 1
      retry
    end
  end
end

require 'redis'
require 'rails'
require 'csv'
require 'rack-mini-profiler'


MIN_QUEUE_SIZE = 3
QUEUE_SIZE = 10
LEFT_MOTOR_ID = 19
RIGHT_MOTOR_ID = 32

def add_points(queue_size)
  queue_size.times do |i|
    path = @redis.get("#{Config.version}_#{@point_index}")

    return if path.nil?

    path = JSON.parse path
    next_left_point = PVT.from_json path['left_motor_points'][@trajectory_point_index]
    next_left_point.t *= 1000

    p [next_left_point, i]
    @left_motor.add_point(next_left_point)

    if @trajectory_point_index < path['left_motor_points'].size - 1
      @trajectory_point_index += 1
    else
      @trajectory_point_index = 1
      @point_index += 1
    end

  rescue => e
    puts e.message
    puts e.backtrace

    @left_motor.velocity = 0.0
    fail 'Cannot send point'
  end
end


def initialize_motor(id)
  @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
  RRServoMotor.new(@servo_interface, id)
end

def do_it
  skip = %w[test.rb loop.rb graph.rb]
  Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
    require_relative f unless skip.any? {|s| s == f}
  end

  @redis = Redis.new

  @point_index = 0
  @trajectory_point_index = 1
  @zero_time = Time.now

  @left_motor = initialize_motor(LEFT_MOTOR_ID)
  @left_motor.clear_points_queue

  left_point = 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
  @left_motor.go_to(pos: left_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)

  @left_motor.add_motion_point(left_point, 0, 1000)
  @servo_interface.start_motion

  begin
    queue_size = @left_motor.queue_size
    p({q: queue_size})
    if queue_size <= MIN_QUEUE_SIZE
      add_points(QUEUE_SIZE)
    end
  end while queue_size > 0

end

# do_it
require 'redis'
require 'rails'
require 'csv'
require 'rack-mini-profiler'

LEFT_MOTOR_ID = 32
RIGHT_MOTOR_ID = 19

def initialize_motor(id)
  @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
  RRServoMotor.new(@servo_interface, id)
end

def do_it
  skip = %w[test.rb loop.rb graph.rb]
  Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
    require_relative f unless skip.any? {|s| s == f}
  end

  @left_motor = initialize_motor(LEFT_MOTOR_ID)
  @right_motor = initialize_motor(RIGHT_MOTOR_ID)


  @left_motor.clear_points_queue
  @right_motor.clear_points_queue

# @redis = Redis.new
#
# left_point = 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
# right_point = 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)
#
# time_left = @left_motor.go_to(pos: left_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)
# time_right = @right_motor.go_to(pos: right_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)
#
# @servo_interface.start_motion
# sleep [time_left, time_right].max + 0.1
#
# time = 0
#
# @point_index = 0
# loop do
#   data = @redis.get("#{Config.version}_#{@point_index}")
#   break if data.nil?
#   path = JSON.parse data
#   path['left_motor_points'][1..-1].each do |point|
#     @left_motor.add_point(PVT.new(point['p'], point['v'], point['t'] * 1000))
#     time += point['t']
#   end
#
#   path['right_motor_points'][1..-1].each do |point|
#     @right_motor.add_point(PVT.new(point['p'], point['v'], point['t'] * 1000))
#   end
#   @point_index += 1
# end

  time = @left_motor.go_to(pos: 1000.0)
# time = @left_motor.go_to(pos: 0.0)
# time = @left_motor.go_to(pos: -500.0, max_velocity: velocity)
  @servo_interface.start_motion
  @left_motor.log_pvt('data.csv', time + 2.0)
  `gnuplot ./plot.gnu`

# sleep(time)

  puts time
end
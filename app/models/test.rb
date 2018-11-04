require 'redis'
require 'rails'
require 'rack-mini-profiler'

Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
  require_relative f unless f == 'test.rb'
end


def initialize_motor(id)
  @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
  RRServoMotor.new(@servo_interface, id)
end


LEFT_MOTOR_ID = 19
@left_motor = initialize_motor(LEFT_MOTOR_ID)

velocity = Config.max_angular_velocity

@left_motor.clear_points_queue
# time = @left_motor.go_to(pos: 500.0, max_velocity: velocity)
# time = @left_motor.go_to(pos: 0.0, max_velocity: velocity)
time = @left_motor.go_to(pos: -500.0, max_velocity: velocity)
@servo_interface.start_motion

sleep(time)
# @left_motor.wait_for_motion_is_finished

puts time

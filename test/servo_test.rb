require 'test_helper'

class ServoTest < Minitest::Test
  LEFT_MOTOR_ID = 19

  def setup
    points = [[767.1, 0, 0.0, 0, :paint], [742.0, -121.2, 0.0, 355, :paint], [716.9, -194.0, 0.0, 146, :paint], [691.9, -219.0, 0.0, 115, :paint], [666.8, -221.9, 0.0, 112, :paint], [641.7, -220.9, 0.0, 112, :paint], [616.7, -220.8, 0.0, 113, :paint], [591.6, -218.9, 0.0, 113, :paint], [566.5, -193.8, 0.0, 115, :paint], [541.5, -121.0, 0.0, 146, :paint], [516.4, 0, 0.0, 355, :paint]]
    left_motor_points = points.map { |point| PVAT.new(point[0], point[1], point[2], point[3]) }
    @trajectory = Trajectory.new(left_motor_points, left_motor_points, 0, "M800.0,900.0 L780.0,880.0 L760.0,860.0 L740.0,840.0 L720.0,820.0 L700.0,800.0 L680.0,780.0 L660.0,760.0 L640.0,740.0 L620.0,720.0 L600.0,700.0 ")

    if Config.rpi?
      @servo_interface = RRInterface.new
      @left_motor = RRServoMotor.new(@servo_interface, LEFT_MOTOR_ID)
    else
      @servo_interface = RRInterface.new
      @left_motor = RRServoMotor.new(@servo_interface, LEFT_MOTOR_ID)
    end
    @left_motor.clear_points_queue
  end

  def run_trajectory(trajectory)
    tl = @left_motor.move(to: trajectory.left_motor_points.first.p, max_velocity: 101.0, acceleration: 200)
    @servo_interface.start_motion
    sleep tl / 1000.0 + 1.0
    assert_equal((trajectory.left_motor_points.first.p - @left_motor.position).round, 0)
    trajectory.left_motor_points[1..-1].each do |point|
      p point
      @left_motor.add_point point
    end
    p @left_motor.queue_size
    @servo_interface.start_motion
    sleep trajectory.left_motor_points.map(&:t).reduce(&:+) / 1000.0 + 1.0
    assert_equal((trajectory.left_motor_points.last.p - @left_motor.position).round, 0)
  end

  def test_trajectory
    run_trajectory(@trajectory)
  end

  def test_trajectory_from_redis
    run_trajectory(Trajectory.get 3)
    run_trajectory(Trajectory.get 1)
    run_trajectory(Trajectory.get 0)
  end

  def teardown
  end
end

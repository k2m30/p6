require 'test_helper'

class PrevNextTest < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    Config.start_from = 0
    @image = build_image 'risovaka007_003.svg'
    name = @image.layers.keys[rand(1..@image.layers.keys.size)]
    @layer = build_layer(name)
  end

  def build_layer(name = @layer.name)
    p 'Layer name: ' + name
    @image.get_layer(name)
    @layer = Layer.build(name)
    puts '____________________________________________________________________________'
    @layer
  end

  def test_next
    start_from = Config.start_from
    assert start_from.zero?, 'Start must be zero after build'
    t0_before = Trajectory.get 0
    t1_before = Trajectory.get 1
    t2_before = Trajectory.get 2

    assert(!t0_before.empty?)
    assert(!t1_before.empty?)
    assert(!t2_before.empty?)

    assert t0_before.left_motor_points.first.p == 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
    assert t0_before.right_motor_points.first.p == 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)

    assert t1_before.left_motor_points.first.p != 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
    assert t1_before.right_motor_points.first.p != 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)

    assert t2_before.left_motor_points.first.p != 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
    assert t2_before.right_motor_points.first.p != 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)

    Trajectory.next

    assert Config.start_from - start_from == 1, 'Start_form must be changed after next action'

    Trajectory.next

    assert Config.start_from == 2, 'start from must be 2'

    new_layer = Layer.build(@layer.name)
    t0_after = Trajectory.get 0
    t1_after = Trajectory.get 1
    t2_after = Trajectory.get 2

    assert(t0_after.empty?)
    assert(t1_after.empty?)
    assert(!t2_after.empty?)

    assert t2_after.left_motor_points.first.p == 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
    assert t2_after.right_motor_points.first.p == 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)

    assert t2_before.left_motor_points[1..-1] != t2_after.left_motor_points[1..-1] and t2_before.right_motor_points[1..-1] != t2_after.right_motor_points[1..-1]
  ensure
    Config.start_from = 0

  end
end

require 'test_helper'

class PrevNextTest < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    Config.push
    Config.start_from = 0
    Config.canvas_size_x = 6000.0
    Config.initial_x = 3500.0
    Config.initial_y = 3500.0
    Config.max_segment_length = 30.0
    @image = build_image 'risovaka007_003.svg'
    name = @image.layers.keys[rand(1..@image.layers.keys.size-1)]
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

    point_0 = @layer.tpaths[0].elements.first.end_point.get_motors_deg
    assert t0_before.left_motor_points.first.p == point_0.x
    assert t0_before.right_motor_points.first.p == point_0.y

    assert t1_before.left_motor_points.first.p != point_0.x
    assert t1_before.right_motor_points.first.p != point_0.y

    assert t2_before.left_motor_points.first.p != point_0.x
    assert t2_before.right_motor_points.first.p != point_0.y

    Trajectory.next

    assert Config.start_from - start_from == 1, 'Start_form must be changed after next action'

    Trajectory.next

    assert Config.start_from == 2, 'start from must be 2'

    Layer.build(@layer.name)
    t0_after = Trajectory.get 0
    t1_after = Trajectory.get 1
    t2_after = Trajectory.get 2

    assert(t0_after.empty?)
    assert(t1_after.empty?)
    assert(!t2_after.empty?)

    assert t2_before.left_motor_points[1..-1] != t2_after.left_motor_points[1..-1] and t2_before.right_motor_points[1..-1] != t2_after.right_motor_points[1..-1]
  end

  def teardown
    Config.pop
  end
end

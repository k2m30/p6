require 'test_helper'

class MoveToTest < Minitest::Test

  def setup
  end

  def test_move_to
    dx = 8
    dy = 4
    start_point = Point.new(10, 100)
    end_point = Point.new(15, 340)
    control_point_1 = Point.new(20, 20)
    control_point_2 = Point.new(200, 200)
    move_to = MoveTo.new([start_point.dup, end_point.dup])
    line = Line.new([start_point.dup, end_point.dup])
    curve = CubicCurve.new([start_point.dup, control_point_1.dup, control_point_2.dup, end_point.dup])

    p move_to
    [move_to, line, curve].each { |e| e.move!(dx, dy) }

    p move_to.to_s
    assert_equal 'M23.0,344.0 ', move_to.to_s
    assert_equal 'L23.0,344.0 ', line.to_s
    assert_equal 'C28.0,24.0 208.0,204.0 23.0,344.0 ', curve.to_s
    assert_equal move_to.start_point, Point.new(start_point.x + dx, start_point.y + dy)
    assert_equal line.start_point, Point.new(start_point.x + dx, start_point.y + dy)
    assert_equal curve.start_point, Point.new(start_point.x + dx, start_point.y + dy)
  end
end


require 'test_helper'

class InverseKinematicTest < Minitest::Test
  N = 1000

  def setup
    Redis.new.flushall
    puts '____________________________________________________________________________'
  end

  def test_kinematic
    width = Config.canvas_size_x
    height = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy

    N.times do
      point = Point.new(rand(0..width).round(2), rand(0..height).round(2))
      inverse_point = point.inverse(width, dm, dy)
      decart_point = inverse_point.to_decart(width, dm, dy)

      assert decart_point.x.round(4) == point.x.round(4) and decart_point.y.round(4) == point.y.round(4)
    end
  end
end

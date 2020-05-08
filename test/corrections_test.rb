require 'test_helper'

class CorrectionTest < Minitest::Test


  def setup
    Redis.new.flushall
    Config.push
    Config.image_name = 'test.svg'
    Config.canvas_size_x = 1200
    Config.canvas_size_y = 1500
    Config.dm = 200
    Config.dy = 100
    Config.max_segment_length = 20
    Config.initial_x = Math.sqrt(300 ** 2 + 200 ** 2)
    Config.initial_y = Math.sqrt(700 ** 2 + 200 ** 2)
    Config.correction_left = 200.0
    Config.correction_right = 250.0

    @image = build_image
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end


  def test_corrections
    correction_left = Config.correction_left
    correction_right = Config.correction_right
    initial_point = Config.start_point
    belts_with_correction = initial_point.get_belts_length
    belts_without_correction = initial_point.get_belts_length(Config.motor_pulley_diameter, 0, 0)

    assert((belts_with_correction.x - belts_without_correction.x).round(4) == correction_left, "Wrong belt correction calculation")
    assert((belts_with_correction.y - belts_without_correction.y).round(4) == correction_right, "Wrong belt correction calculation")

    @image.get_layer_names
    assert @image.layers.keys.size == 1

    @image.layers.keys.each do |name|
      @image.get_layer(name)
      @layer = Layer.build(name)

    end
  end

  def teardown
    Config.pop
  end
end

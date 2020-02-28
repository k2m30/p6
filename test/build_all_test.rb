require 'test_helper'

class BuildTest < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    Config.push
  end

  def test_builds_risovaka
    Config.canvas_size_x = 6000.0
    Config.initial_x = 3500.0
    Config.initial_y = 3500.0
    Config.max_segment_length = 30.0
    @image = build_image 'risovaka007_003.svg'
    build_all_layers
  end

  def test_builds_hare
    Config.canvas_size_x = 1310.0
    Config.initial_x = 750.0
    Config.initial_y = 750.0
    Config.max_segment_length = 30.0
    @image = build_image 'hare_1310.svg'
    build_all_layers
  end

  def test_builds_flying
    Config.canvas_size_x = 10600.0
    Config.initial_x = 6000.0
    Config.initial_y = 6000.0
    Config.max_segment_length = 30.0
    @image = build_image 'flying.svg'
    build_all_layers
  end

  def build_all_layers
    @image.layers.keys.each do |name|
      p 'Building: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

  def teardown
    Config.pop
  end
end
require 'test_helper'

MiniTest::Reporters.use!

class SimpleDrawingTest < Minitest::Test


  def setup
    Redis.new.flushall
    Config.push
    Config.image_name = 'test.svg'
    Config.canvas_size_x = 120
    Config.canvas_size_y = 150
    Config.dm = 20
    Config.dy = 10
    Config.max_segment_length = 2
    Config.initial_x = Math.sqrt(30**2 + 20**2)
    Config.initial_y = Math.sqrt(70**2 + 20**2)


    file_name = Config.image_name
    path = Rails.root.join("app", "assets", "images")
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

  def test_kinematic
    width = Config.canvas_size_x
    height = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy

    @image.get_layer_names
    assert @image.layers.keys.size == 1

    @image.layers.keys.each do |name|
      @image.get_layer(name)
      layer = Layer.build(name)

      pp layer.paths
      p "----"
      pp layer.splitted_paths
      p "----"
      pp layer.tpaths

    end

  ensure
    Config.pop
  end
end

require 'test_helper'

require "minitest/autorun"
require 'minitest/reporters'

MiniTest::Reporters.use!

class BuildTest < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
  end

  def builds_risovaka
    file_name = 'risovaka007_003.svg'
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

  def test_builds_flying
    file_name = 'flying.svg'
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      @image.get_layer(name)
      layer = Layer.build(name)
      layer.splitted_paths.zip layer.tpaths do |sp, tp|
        sp.elements.zip tp.elements do |sp_e, tp_e|
          unless sp_e.start_point == tp_e.start_point.to_decart
            pp sp_e.start_point
            pp tp_e.start_point.to_decart
            exit 1

          end
          begin
            if sp_e.end_point == tp_e.end_point.to_decart

            end
          rescue => e
          end
        end
      end

      # layer.splitted_paths.zip layer.trajectories do |s, t|
      #   p s.elements.size, t.left_motor_points.size
      #   pp t.left_motor_points
      #   start_index = t.left_motor_points.map(&:v)[1..-1].index(0) + 1
      #   x = t.left_motor_points[start_index].p * (Math::PI * Config.motor_pulley_diameter) / 360.0
      #   y = t.right_motor_points[start_index].p * (Math::PI * Config.motor_pulley_diameter) / 360.0
      #   point = Point.new x, y
      #   p '____________'
      #   # p s.start_point
      #   # p point
      #   # p point.to_decart
      #   assert s.elements.first.end_point == point.to_decart
      #   p :passed
      # end
      puts '____________________________________________________________________________'

    end
  end

end
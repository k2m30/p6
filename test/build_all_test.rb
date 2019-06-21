require 'test_helper'

class BuildTest < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    Config.push
  end

  def test_builds_risovaka
    @image = build_image 'risovaka007_003.svg'
    build_all_layers
  ensure
    Config.pop
  end

  def test_builds_flying
    @image = build_image 'flying.svg'
    build_all_layers
  ensure
    Config.pop
  end

  def build_all_layers
    @image.layers.keys.each do |name|
      p 'Building: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

end
require "minitest/autorun"

class TestBuild < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
  end

  def test_builds_risovaka
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
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

end
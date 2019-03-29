require "minitest/autorun"

class TestBuild < Minitest::Test
  def setup
    Redis.new.flushall
  end

  def test_builds_risovaka
    file_name = 'risovaka007_003.svg'
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      p '---------------'

      @image.get_layer(name)
      Layer.build(name)

      p name + ' tested'
      p '---------------'
    end
  end

  def test_builds_flying
    file_name = 'flying.svg'
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      p '---------------'

      @image.get_layer(name)
      Layer.build(name)

      p name + ' tested'
      p '---------------'
    end
  end

end
require "minitest/autorun"

class PrevNext < Minitest::Test
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    file_name = 'risovaka007_003.svg'
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer_names
    name = @image.layers.keys[rand(1..@image.layers.keys.size)]
    @layer = build_layer(name)
  end

  def build_layer(name)
    p 'Layer name: ' + name
    @image.get_layer(name)
    Layer.build(name)
    puts '____________________________________________________________________________'
  end

  def test_next
    start_from = Config.start_from
    assert start_from.zero?, 'Start must be zero after build'

    Trajectory.next

    assert Config.start_from - start_from == 1, 'Start_form must be changed after next action'

    Trajectory.next

    assert Config.start_from == 2, 'start from must be 2'

  end
end

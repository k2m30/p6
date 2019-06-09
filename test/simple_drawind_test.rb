require 'test_helper'

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
    Config.initial_x = Math.sqrt(30 ** 2 + 20 ** 2)
    Config.initial_y = Math.sqrt(70 ** 2 + 20 ** 2)


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

  def test_drawing
    width = Config.canvas_size_x
    height = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy

    @image.get_layer_names
    assert @image.layers.keys.size == 1

    @image.layers.keys.each do |name|
      @image.get_layer(name)
      layer = Layer.build(name)

      assert layer.paths[0].d == 'M40.0,60.0 L90.0,60.0 L90.0,130.0 L40.0,130.0 L40.0,60.0 L40.0,60.0 '
      assert layer.paths[1].d == 'M60.0,70.0 L80.0,90.0 '
      assert layer.paths[2].d == 'M80.0,90.0 L50.0,90.0 '
      assert layer.paths[3].d == 'M50.0,90.0 L60.0,70.0 '
      assert layer.paths[4].d == 'M40.0,30.0 '

      assert layer.splitted_paths[0].d == 'M40.0,60.0 L42.0,60.0 L44.0,60.0 L46.0,60.0 L48.0,60.0 L50.0,60.0 L52.0,60.0 L54.0,60.0 L56.0,60.0 L58.0,60.0 L60.0,60.0 L62.0,60.0 L64.0,60.0 L66.0,60.0 L68.0,60.0 L70.0,60.0 L72.0,60.0 L74.0,60.0 L76.0,60.0 L78.0,60.0 L80.0,60.0 L82.0,60.0 L84.0,60.0 L86.0,60.0 L88.0,60.0 L90.0,60.0 L90.0,62.0 L90.0,64.0 L90.0,66.0 L90.0,68.0 L90.0,70.0 L90.0,72.0 L90.0,74.0 L90.0,76.0 L90.0,78.0 L90.0,80.0 L90.0,82.0 L90.0,84.0 L90.0,86.0 L90.0,88.0 L90.0,90.0 L90.0,92.0 L90.0,94.0 L90.0,96.0 L90.0,98.0 L90.0,100.0 L90.0,102.0 L90.0,104.0 L90.0,106.0 L90.0,108.0 L90.0,110.0 L90.0,112.0 L90.0,114.0 L90.0,116.0 L90.0,118.0 L90.0,120.0 L90.0,122.0 L90.0,124.0 L90.0,126.0 L90.0,128.0 L90.0,130.0 L88.0,130.0 L86.0,130.0 L84.0,130.0 L82.0,130.0 L80.0,130.0 L78.0,130.0 L76.0,130.0 L74.0,130.0 L72.0,130.0 L70.0,130.0 L68.0,130.0 L66.0,130.0 L64.0,130.0 L62.0,130.0 L60.0,130.0 L58.0,130.0 L56.0,130.0 L54.0,130.0 L52.0,130.0 L50.0,130.0 L48.0,130.0 L46.0,130.0 L44.0,130.0 L42.0,130.0 L40.0,130.0 L40.0,128.0 L40.0,126.0 L40.0,124.0 L40.0,122.0 L40.0,120.0 L40.0,118.0 L40.0,116.0 L40.0,114.0 L40.0,112.0 L40.0,110.0 L40.0,108.0 L40.0,106.0 L40.0,104.0 L40.0,102.0 L40.0,100.0 L40.0,98.0 L40.0,96.0 L40.0,94.0 L40.0,92.0 L40.0,90.0 L40.0,88.0 L40.0,86.0 L40.0,84.0 L40.0,82.0 L40.0,80.0 L40.0,78.0 L40.0,76.0 L40.0,74.0 L40.0,72.0 L40.0,70.0 L40.0,68.0 L40.0,66.0 L40.0,64.0 L40.0,62.0 L40.0,60.0 '
      assert layer.splitted_paths[1].d == 'M60.0,70.0 L61.33,71.33 L62.67,72.67 L64.0,74.0 L65.33,75.33 L66.67,76.67 L68.0,78.0 L69.33,79.33 L70.67,80.67 L72.0,82.0 L73.33,83.33 L74.67,84.67 L76.0,86.0 L77.33,87.33 L78.67,88.67 L80.0,90.0 '
      assert layer.splitted_paths[2].d == 'M80.0,90.0 L78.0,90.0 L76.0,90.0 L74.0,90.0 L72.0,90.0 L70.0,90.0 L68.0,90.0 L66.0,90.0 L64.0,90.0 L62.0,90.0 L60.0,90.0 L58.0,90.0 L56.0,90.0 L54.0,90.0 L52.0,90.0 L50.0,90.0 '
      assert layer.splitted_paths[3].d == 'M50.0,90.0 L50.83,88.33 L51.67,86.67 L52.5,85.0 L53.33,83.33 L54.17,81.67 L55.0,80.0 L55.83,78.33 L56.67,76.67 L57.5,75.0 L58.33,73.33 L59.17,71.67 L60.0,70.0 '
      assert layer.splitted_paths[4].d == 'M40.0,30.0 '

      layer.splitted_paths.zip(layer.tpaths).each do |sp, tp|
        sp.elements.zip(tp.elements).each do |se, te|
          inverse_point = se.start_point.inverse(width, dm, dy)
          decart_point = te.start_point.to_decart(width, dm, dy)
          assert (inverse_point.x.round(4) == te.start_point.x.round(4) and inverse_point.y.round(4) == te.start_point.y.round(4)), "#{inverse_point}, #{te}"
          assert (se.start_point.x.round(4) == decart_point.x.round(4) and se.start_point.y.round(4) == decart_point.y.round(4)), "#{se}, #{decart_point}"

          inverse_point = se.end_point.inverse(width, dm, dy)
          decart_point = te.end_point.to_decart(width, dm, dy)
          assert inverse_point.x.round(4) == te.end_point.x.round(4) and inverse_point.y.round(4) == te.end_point.y.round(4)
          assert se.end_point.x.round(4) == decart_point.x.round(4) and se.end_point.y.round(4) == decart_point.y.round(4)
        end
      end

    end

  ensure
    Config.pop
  end
end

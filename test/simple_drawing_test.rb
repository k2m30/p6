require 'test_helper'

class SimpleDrawingTest < Minitest::Test


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


    @image = build_image
    @image.layers.keys.each do |name|
      p 'Layer name: ' + name
      @image.get_layer(name)
      Layer.build(name)
      puts '____________________________________________________________________________'
    end
  end

  def test_drawing
    @image.get_layer_names
    assert @image.layers.keys.size == 1

    @image.layers.keys.each do |name|
      @image.get_layer(name)
      @layer = Layer.build(name)

      check_paths
      check_splitted_paths
      check_tpaths
      check_trajectories
      # check_trajectories_in_browser
      check_linear_velocity
    end

  ensure
    Config.pop
  end

  def check_linear_velocity
    linear_velocities = []
    # positions = [Point.new(Config.initial_x, Config.initial_y).to_decart]
    positions = []
    distances = []
    dts = []
    @layer.trajectories.each_with_index do |t, i|
      positions[i] = []
      dts[i] = []
      t.left_motor_points.zip(t.right_motor_points) do |r, l|
        positions[i] << Point.new(r.p, l.p).get_belts_length.to_decart
        dts[i] << (r.t + l.t) / 2.0
      end
    end

    positions.each_with_index do |trajectory_positions, i|
      distances[i] = [0]
      trajectory_positions.each_cons(2) do |prev, curr|
        distances[i] << Point.distance(prev, curr)
      end
    end

    distances.each_with_index do |trajectory_distance, i|
      linear_velocities[i] = [0]
      trajectory_distance.zip(dts[i])[1..-1].each do |distance, dt|
        linear_velocities[i] << distance / dt
      end
    end

    linear_velocities.each_with_index do |linear_velocity, i|
      file_name = "linear_velocity_#{i}.html"
      # Plot.html(x: dts[i].cumsum, y: linear_velocity, file_name: file_name)
    end
  end

  def check_trajectories_in_browser
    @layer.trajectories.each_index do |i|
      file_name = Plot.trajectory(n: i)
      `open -a Safari #{file_name}`
    end
  end

  def check_trajectories
    diameter = Config.motor_pulley_diameter
    assert(@layer.trajectories.size == @layer.tpaths.size, "Trajectories and tpaths size must be equal")
    @layer.tpaths.zip(@layer.trajectories).each do |tpath, trajectory|

      points_left = ([trajectory.left_motor_points.select {|point| !point.paint}.last&.p] + trajectory.left_motor_points.select {|point| point.paint}&.map(&:p)).compact
      points_right = ([trajectory.right_motor_points.select {|point| !point.paint}.last&.p] + trajectory.right_motor_points.select {|point| point.paint}&.map(&:p)).compact

      assert(points_left.size == points_right.size, "Trajectories size must be equal")

      points_left.zip(points_right).zip(tpath.elements).each do |points, te|
        point = te.end_point.get_motors_deg(diameter)
        assert(points == [point.x, point.y], 'Trajectories calculations wrong')
      end
      assert trajectory.left_motor_points.map(&:t).sum.round(6) == trajectory.right_motor_points.map(&:t).sum.round(6)
      # assert trajectory.left_motor_points.map(&:t).map{|t| t.round(6)} == trajectory.right_motor_points.map(&:t).map{|t| t.round(6)}
    end
  end

  def check_paths
    #                         d="M400,600 L900,600 L900,1300 L400,1300 L400,600 z"
    assert @layer.paths[0].d == 'M400.0,600.0 L900.0,600.0 L900.0,1300.0 L400.0,1300.0 L400.0,600.0 L400.0,600.0 '
    # assert @layer.paths[0].d == 'M400.0,600.0 L400.0,600.0 L400.0,1300.0 L900.0,1300.0 L900.0,600.0 L400.0,600.0 '
    assert @layer.paths[1].d == 'M600.0,700.0 L800.0,900.0 '
    assert @layer.paths[2].d == 'M800.0,900.0 L500.0,900.0 '
    assert @layer.paths[3].d == 'M500.0,900.0 L600.0,700.0 '
    assert @layer.paths[4].d == 'M400.0,300.0 '
  end

  def check_splitted_paths
    assert @layer.splitted_paths[0].d == 'M400.0,600.0 L420.0,600.0 L440.0,600.0 L460.0,600.0 L480.0,600.0 L500.0,600.0 L520.0,600.0 L540.0,600.0 L560.0,600.0 L580.0,600.0 L600.0,600.0 L620.0,600.0 L640.0,600.0 L660.0,600.0 L680.0,600.0 L700.0,600.0 L720.0,600.0 L740.0,600.0 L760.0,600.0 L780.0,600.0 L800.0,600.0 L820.0,600.0 L840.0,600.0 L860.0,600.0 L880.0,600.0 L900.0,600.0 L900.0,620.0 L900.0,640.0 L900.0,660.0 L900.0,680.0 L900.0,700.0 L900.0,720.0 L900.0,740.0 L900.0,760.0 L900.0,780.0 L900.0,800.0 L900.0,820.0 L900.0,840.0 L900.0,860.0 L900.0,880.0 L900.0,900.0 L900.0,920.0 L900.0,940.0 L900.0,960.0 L900.0,980.0 L900.0,1000.0 L900.0,1020.0 L900.0,1040.0 L900.0,1060.0 L900.0,1080.0 L900.0,1100.0 L900.0,1120.0 L900.0,1140.0 L900.0,1160.0 L900.0,1180.0 L900.0,1200.0 L900.0,1220.0 L900.0,1240.0 L900.0,1260.0 L900.0,1280.0 L900.0,1300.0 L880.0,1300.0 L860.0,1300.0 L840.0,1300.0 L820.0,1300.0 L800.0,1300.0 L780.0,1300.0 L760.0,1300.0 L740.0,1300.0 L720.0,1300.0 L700.0,1300.0 L680.0,1300.0 L660.0,1300.0 L640.0,1300.0 L620.0,1300.0 L600.0,1300.0 L580.0,1300.0 L560.0,1300.0 L540.0,1300.0 L520.0,1300.0 L500.0,1300.0 L480.0,1300.0 L460.0,1300.0 L440.0,1300.0 L420.0,1300.0 L400.0,1300.0 L400.0,1280.0 L400.0,1260.0 L400.0,1240.0 L400.0,1220.0 L400.0,1200.0 L400.0,1180.0 L400.0,1160.0 L400.0,1140.0 L400.0,1120.0 L400.0,1100.0 L400.0,1080.0 L400.0,1060.0 L400.0,1040.0 L400.0,1020.0 L400.0,1000.0 L400.0,980.0 L400.0,960.0 L400.0,940.0 L400.0,920.0 L400.0,900.0 L400.0,880.0 L400.0,860.0 L400.0,840.0 L400.0,820.0 L400.0,800.0 L400.0,780.0 L400.0,760.0 L400.0,740.0 L400.0,720.0 L400.0,700.0 L400.0,680.0 L400.0,660.0 L400.0,640.0 L400.0,620.0 L400.0,600.0 '
    assert @layer.splitted_paths[1].d == 'M600.0,700.0 L613.33,713.33 L626.67,726.67 L640.0,740.0 L653.33,753.33 L666.67,766.67 L680.0,780.0 L693.33,793.33 L706.67,806.67 L720.0,820.0 L733.33,833.33 L746.67,846.67 L760.0,860.0 L773.33,873.33 L786.67,886.67 L800.0,900.0 '
    assert @layer.splitted_paths[2].d == 'M800.0,900.0 L780.0,900.0 L760.0,900.0 L740.0,900.0 L720.0,900.0 L700.0,900.0 L680.0,900.0 L660.0,900.0 L640.0,900.0 L620.0,900.0 L600.0,900.0 L580.0,900.0 L560.0,900.0 L540.0,900.0 L520.0,900.0 L500.0,900.0 '
    assert @layer.splitted_paths[3].d == 'M500.0,900.0 L508.33,883.33 L516.67,866.67 L525.0,850.0 L533.33,833.33 L541.67,816.67 L550.0,800.0 L558.33,783.33 L566.67,766.67 L575.0,750.0 L583.33,733.33 L591.67,716.67 L600.0,700.0 '
    assert @layer.splitted_paths[4].d == 'M400.0,300.0 '
  end

  def check_tpaths
    width = Config.canvas_size_x
    # height = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy

    @layer.splitted_paths.zip(@layer.tpaths).each do |sp, tp|
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

  def teardown
    Config.pop
  end
end

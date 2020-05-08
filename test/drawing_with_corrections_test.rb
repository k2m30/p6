require 'test_helper'

class DrawingCorrectionsTest < Minitest::Test


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

  def test_drawing
    @image.get_layer_names
    assert @image.layers.keys.size == 1

    @image.layers.keys.each do |name|
      @image.get_layer(name)
      @layer = Layer.build(name)

      check_trajectories
      check_linear_velocity
    end

  ensure
    Config.pop
  end

  def check_linear_velocity
    linear_velocities = []
    # positions = [Config.start_point.to_decart]
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

  def teardown
    Config.pop
  end
end

require 'csv'

class Trajectory
  attr_accessor :left_motor_points, :right_motor_points, :id

  def initialize(left_motor_points, right_motor_points, id = nil)
    fail unless left_motor_points.is_a? Array and right_motor_points.is_a? Array
    fail if left_motor_points.size != right_motor_points.size

    @left_motor_points = left_motor_points
    @right_motor_points = right_motor_points
  end

  def self.build(spath, tpath)
    fail if spath.elements.size != tpath.elements.size

    max_linear_velocity = Config.linear_velocity
    angular_velocity = Config.max_angular_velocity
    angular_acceleration = Config.max_angular_acceleration
    linear_acceleration = Config.linear_acceleration
    diameter = Config.motor_pulley_diameter

    r = Row.new
    r.x = spath.elements.first.end_point.x
    r.y = spath.elements.first.end_point.y
    r.dl = 0.0
    r.left_mm = tpath.elements.first.end_point.x
    r.right_mm = tpath.elements.first.end_point.y
    r.left_deg = 360.0 * tpath.elements.first.end_point.x / (Math::PI * diameter)
    r.right_deg = 360.0 * tpath.elements.first.end_point.y / (Math::PI * diameter)
    r.l = 0.0
    r.linear_velocity = 0.0
    r.t = 0.0
    r.dt = 0.0
    r.v_average_left = 0.0
    r.v_average_right = 0.0
    r.v_left = 0.0
    r.v_right = 0.0

    data = [r]

    velocity_spline = VelocitySpline.create(length: spath.length,
                                            linear_acceleration: linear_acceleration,
                                            max_linear_velocity: max_linear_velocity) unless spath.length.zero?

    tpath.elements.each_with_index do |curr, i|
      next if i.zero?
      prev_r = data[i - 1]

      r = Row.new
      r.x = spath.elements[i].end_point.x
      r.y = spath.elements[i].end_point.y
      r.dl = spath.elements[i].length

      r.left_mm = curr.end_point.x
      r.right_mm = curr.end_point.y

      r.left_deg = 360.0 * r.left_mm / (Math::PI * diameter)
      r.right_deg = 360.0 * r.right_mm / (Math::PI * diameter)
      r.l = prev_r.l + r.dl

      r.t = velocity_spline.time_at(s: r.l)
      r.linear_velocity = velocity_spline[r.t]

      r.dt = r.t - prev_r.t
      fail 'spath discretization is too small' if r.dt.zero?

      r.v_average_left = (r.left_deg - prev_r.left_deg) / r.dt
      r.v_average_right = (r.right_deg - prev_r.right_deg) / r.dt

      r.v_left = r.v_average_left
      r.v_right = r.v_average_right
      data << r
    end

    # data.each_cons(2) do |r, r_next|
    #   r.v_left = (r.v_average_left + r_next.v_average_left) / 2
    #   r.v_right = (r.v_average_right + r_next.v_average_right) / 2
    # end

    # fail 'Wrong time calculation' if data[1..-1].map(&:dt).sum - (t1 + t2 + t3) > 0.0001
    data.first.v_left = 0.0
    data.first.v_right = 0.0
    data.last.v_left = 0.0
    data.last.v_right = 0.0

    # fail 'nil values found during trajectory calculation' if data.any? {|d| d.left_deg.nil? or d.right_deg.nil? or d.v_left.nil? or d.v_right.nil? or d.dt.nil?}
    # Plot.html x: data.map(&:t), y: data.map(&:v_left), file_name: 'v_left.html'
    # Plot.html x: data.map(&:t), y: data.map(&:v_average_left), file_name: 'v_average_left.html'
    # Plot.html x: data.map(&:t), y: data.map(&:dt), file_name: 'dt.html'
    # Plot.html x: data.map(&:t), y: data.map(&:linear_velocity), file_name: 'linear_velocity.html'
    # Plot.html x: (0..data.size).to_a, y: data.map(&:dt), file_name: 'dt2.html'
    # Plot.html x: (0..data.map(&:t).size).to_a, y: data.map(&:t), file_name: 't.html'

    data[1..-1].each_cons(3) do |first, second, third|
      if (first.left_deg < second.left_deg and third.left_deg < second.left_deg) or (first.left_deg > second.left_deg and third.left_deg > second.left_deg)
        second.v_left = 0
      end

      if (first.right_deg < second.right_deg and third.right_deg < second.right_deg) or (first.right_deg > second.right_deg and third.right_deg > second.right_deg)
        second.v_right = 0
      end
    end

    data.each_cons(2) do |first, second|
      if (second.left_deg - first.left_deg) > 0
        if second.v_left < 0
          fail 'Over zero velocity move failed'
        end
      else
        if second.v_left > 0
          fail 'Over zero velocity move failed'
        end
      end

      if (second.right_deg - first.right_deg) > 0
        if second.v_right < 0
          fail 'Over zero velocity move failed'
        end
      else
        if second.v_right > 0
          fail 'Over zero velocity move failed'
        end
      end
    end

    # first add move_to commands
    move_to_left_deg = 360.0 * tpath.elements.first.start_point.x / (Math::PI * diameter)
    move_to_right_deg = 360.0 * tpath.elements.first.start_point.y / (Math::PI * diameter)

    left_motor_points = RRServoMotor.get_move_to_points(from: move_to_left_deg, to: data[0].left_deg, max_velocity: angular_velocity, acceleration: angular_acceleration)
    right_motor_points = RRServoMotor.get_move_to_points(from: move_to_right_deg, to: data[0].right_deg, max_velocity: angular_velocity, acceleration: angular_acceleration)


    time_left = left_motor_points.map(&:t).sum
    time_right = right_motor_points.map(&:t).sum

    time_diff = time_left - time_right
    size_diff = left_motor_points.size - right_motor_points.size

    if size_diff.zero?
      if time_diff > 0
        right_motor_points.last.t += time_diff.abs
      else
        left_motor_points.last.t += time_diff.abs
      end
    elsif size_diff > 0 #left trajectory longer
      position = right_motor_points.last.p
      dt = (time_diff / size_diff).abs
      size_diff.times do
        right_motor_points << PVT.new(position, 0.0, dt)
      end
    else #right trajectory longer
      position = left_motor_points.last.p
      dt = (time_diff / size_diff).abs
      size_diff.abs.times do
        left_motor_points << PVT.new(position, 0.0, dt)
      end
    end

    fail 'Left and right motors trajectory have different size' unless left_motor_points.size == right_motor_points.size
    time_left = left_motor_points.map(&:t).sum
    time_right = right_motor_points.map(&:t).sum

    fail 'Trajectories time is different' unless time_left == time_right


    data[1..-1].each do |r|
      dt = (r.dt * 1000)
      left_motor_points.push PVT.new(r.left_deg, r.v_left, dt)
      right_motor_points.push PVT.new(r.right_deg, r.v_right, dt)
    end

    Trajectory.new left_motor_points, right_motor_points
  end

  def self.from_json(json)
    left_motor_points = []
    right_motor_points = []
    json['left_motor_points'].each {|e| left_motor_points.push PVT.new(e['p'], e['v'], e['t'])}
    json['right_motor_points'].each {|e| right_motor_points.push PVT.new(e['p'], e['v'], e['t'])}
    Trajectory.new(left_motor_points, right_motor_points, json['id'])
  end

  def self.plot_path(n, file_name)
    v = Config.version
    trajectory = JSON.parse Redis.new.get("#{v}_#{n}")
    file_name = "#{file_name.to_s}"

    Numo.gnuplot do
      reset
      unset :multiplot
      set title: "trajectory #{n}, left motor"
      set ylabel: ''
      set autoscale: :fix
      set xlabel: 'time, ms'

      set terminal: ['svg', 'size 1200,1600']
      set output: file_name
      set multiplot: 'layout 5,1'

      set grid: 'ytics mytics' # draw lines for each ytics and mytics
      set grid: 'xtics mytics' # draw lines for each ytics and mytics
      set mytics: 2
      set :grid
      # left
      t = []
      time_deltas = trajectory['left_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}

      velocity = trajectory['left_motor_points'].map {|e| e['v']}
      position = trajectory['left_motor_points'].map {|e| e['p']}
      acceleration = [0]
      velocity.zip(time_deltas).each_cons(2) do |curr_vt, next_vt|
        acceleration << (next_vt[0] - curr_vt[0]) / next_vt[1]
      end

      dt = 0.01
      a = Array[0] * time_deltas.size
      tt, q, vq = PositionSpline.qupsample(position, velocity, a, time_deltas.map {|td| td / 1000.0}, dt)
      tt.map! {|t| t * 1000.0}
      set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"

      set title: "trajectory #{n}, left motor"
      set xrange: "[0:#{t.last.ceil(-3)}]"

      set yrange: "[#{position.min.floor(-2)}:#{position.max.ceil(-2)}]"
      plot [t, position, with: 'l', title: 'Left Motor position'], [tt, q, with: 'l', title: 'Left Motor real Position']

      set yrange: "[#{velocity.min.floor(-2)}:#{velocity.max.ceil(-2)}]"
      plot [t, velocity, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Left Motor Velocity'], [tt, vq, with: 'l', title: 'Left Motor real Velocity']

      ##########################################################
      #right
      ##########################################################

      set title: "trajectory #{n}, right motor"
      t = []
      time_deltas = trajectory['right_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}
      velocity = trajectory['right_motor_points'].map {|e| e['v']}
      position = trajectory['right_motor_points'].map {|e| e['p']}

      dt = 0.01
      a = Array[0] * time_deltas.size
      tt, q, vq = PositionSpline.qupsample(position, velocity, a, time_deltas.map {|td| td / 1000.0}, dt)
      tt.map! {|t| t * 1000.0}

      set xrange: "[0:#{t.last.ceil(-3)}]"
      set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"
      set yrange: "[#{position.min.floor(-2)}:#{position.max.ceil(-2)}]"
      plot [t, position, with: 'l', title: 'Right Motor position'], [tt, q, with: 'l', title: 'Right Motor real Position']

      set yrange: "[#{velocity.min.floor(-2)}:#{velocity.max.ceil(-2)}]"
      plot [t, velocity, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Right Motor Velocity'], [tt, vq, with: 'l', title: 'Right Motor real Velocity']

      ##########################################################
      # figure
      ##########################################################
      position_left = trajectory['left_motor_points'].map {|e| e['p']}
      position_right = trajectory['right_motor_points'].map {|e| e['p']}
      index = trajectory['right_motor_points'].map {|e| e['v']}[0..-2].rindex(0)
      x = []
      y = []
      diameter = Config.motor_pulley_diameter
      width = Config.canvas_size_x
      dm = Config.dm
      dy = Config.dy
      height = Config.canvas_size_y

      position_left.size.times do |i|
        xx = position_left[i] * Math::PI * diameter / 360.0
        yy = position_right[i] * Math::PI * diameter / 360.0
        point = Point.new(xx, yy).to_decart(width, dm, dy)
        x << point.x
        y << height - point.y
      end

      set xrange: "[0:#{width}]"
      set yrange: "[0:#{height}]"
      set size: 'ratio -1'
      set title: "trajectory #{n}, figure"
      unset :xlabel

      plot [x[0..index - 1], y[0..index - 1], w: 'l', title: 'move-to'], [x[index + 1..-1], y[index + 1..-1], w: 'lp', pt: 7, pi: 1, ps: 0.2, title: 'paint']
    end
  end

  def self.to_json
    i = 0
    r = Redis.new
    json = ''
    json << '['
    while (s = r.get("#{Config.version}_#{i}")).present?
      t = Trajectory.from_json(JSON.parse(s))
      t.id = i
      json << t.to_json << ','
      i += 1
    end
    json << ']'
    json.sub!(/,\]$/, ']')
    json
  end

  def self.to_csv(t = 0)
    trajectory = JSON.parse(self.to_json, symbolize_names: true).select {|trajectory| trajectory[:id] == t}.first
    CSV.open("./#{t}.csv", 'wb') do |csv|
      csv << %w(id motor p v t)
      trajectory[:left_motor_points].each do |point|
        csv << [t, :left, point[:p], point[:v], point[:t]]
      end
      # trajectory[:right_motor_points].each do |point|
      #   csv << [t, :right, point[:p], point[:v], point[:t]]
      # end
    end
  end
end
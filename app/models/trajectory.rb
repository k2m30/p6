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
    idling_velocity = Config.idling_velocity

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
    r.dt = spath.get_idling_time(linear_acceleration, idling_velocity)
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
      r.v_average_left = (r.left_deg - prev_r.left_deg) / r.dt
      r.v_average_right = (r.right_deg - prev_r.right_deg) / r.dt

      data << r
    end

    data.each_cons(2) do |r, r_next|
      r.v_left = (r.v_average_left + r_next.v_average_left) / 2
      r.v_right = (r.v_average_right + r_next.v_average_right) / 2
    end

    data.last.v_left = 0.0
    data.last.v_right = 0.0

    # fail 'Wrong time calculation' if data[1..-1].map(&:dt).sum - (t1 + t2 + t3) > 0.0001


    # first add move_to command
    r = Row.new
    r.left_deg = 360.0 * tpath.elements.first.start_point.x / (Math::PI * diameter)
    r.right_deg = 360.0 * tpath.elements.first.start_point.y / (Math::PI * diameter)
    r.dt = 0.0
    r.v_left = 0.0
    r.v_right = 0.0
    r.linear_velocity = 0.0
    r.v_average_left = 0.0
    r.v_average_right = 0.0
    r.t = 0.0
    data.insert(0, r)

    # fail 'nil values found during trajectory calculation' if data.any? {|d| d.left_deg.nil? or d.right_deg.nil? or d.v_left.nil? or d.v_right.nil? or d.dt.nil?}
    left_motor_points = []
    right_motor_points = []
    # Plot.html x: data.map(&:t), y: data.map(&:v_left), file_name: 'v_left.html'
    # Plot.html x: data.map(&:t), y: data.map(&:v_average_left), file_name: 'v_average_left.html'
    # Plot.html x: data.map(&:t), y: data.map(&:dt), file_name: 'dt.html'
    # Plot.html x: data.map(&:t), y: data.map(&:linear_velocity), file_name: 'linear_velocity.html'
    # Plot.html x: (0..data.size).to_a, y: data.map(&:dt), file_name: 'dt2.html'
    # Plot.html x: (0..data.map(&:t).size).to_a, y: data.map(&:t), file_name: 't.html'

    data.each do |r|
      dt = (r.dt * 1000).round(1)
      left_motor_points.push PVT.new(r.left_deg.round(2), r.v_left.round(2), dt)
      right_motor_points.push PVT.new(r.right_deg.round(2), r.v_right.round(2), dt)
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
      set multiplot: 'layout 4,1'

      set grid: 'ytics mytics' # draw lines for each ytics and mytics
      set grid: 'xtics mytics' # draw lines for each ytics and mytics
      set mytics: 2
      set :grid
      # left
      t = []
      time_deltas = trajectory['left_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}
      velocity = trajectory['left_motor_points'].map {|e| e['v'].round(2)}
      position = trajectory['left_motor_points'].map {|e| e['p'].round(2)}
      acceleration = [0]
      velocity.zip(time_deltas).each_cons(2) do |curr_vt, next_vt|
        acceleration << (next_vt[0] - curr_vt[0]) / next_vt[1]
      end

      set xrange: "[0:#{t.last.ceil(-3)}]"
      set yrange: "[#{[velocity.min.floor(-2), position.min.floor(-2)].min}:#{[velocity.max.ceil(-2), position.max.ceil(-2)].max}]"
      set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"

      plot [t, position, with: 'l', title: 'Left Motor position'], [t, velocity, with: 'l', title: 'Left Motor Velocity']

      set yrange: "[#{acceleration.min.floor}:#{acceleration.max.ceil}]"
      plot [t, acceleration, with: 'l', title: 'Left Motor Acceleration']

      #right
      set title: "trajectory #{n}, right motor"
      t = []
      time_deltas = trajectory['right_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}
      velocity = trajectory['right_motor_points'].map {|e| e['v']}
      position = trajectory['right_motor_points'].map {|e| e['p']}

      set xrange: "[0:#{t.last.ceil}]"
      set yrange: "[#{[velocity.min.floor(-2), position.min.floor(-2)].min}:#{[velocity.max.ceil(-2), position.max.ceil(-2)].max}]"
      set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"

      plot [t, position, with: 'l', title: 'Right Motor position'], [t, velocity, with: 'l', title: 'Right Motor Velocity']


      # figure
      position_left = trajectory['left_motor_points'].map {|e| e['p']}
      position_right = trajectory['right_motor_points'].map {|e| e['p']}

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

      plot x, y, w: 'lp' #, smooth: 'csplines'
    end
  end
end
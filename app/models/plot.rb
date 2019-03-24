require_relative 'array'
# require 'redis'
# require_relative 'config'
# require 'json'
# require 'numo/gnuplot'
# require_relative 'position_spline'

class Plot
  DT = 0.01

  def self.trajectory(n:, file_name: "#{n}.html", trajectory: nil)
    v = Config.version
    trajectory ||= JSON.parse Redis.new.get("#{v}_#{n}")
    file_name = "#{file_name.to_s}"

    Numo.gnuplot do
      reset
      unset :multiplot
      set ylabel: ''
      set autoscale: :fix
      set xlabel: 'time, ms'

      set terminal: ['svg', 'size 1200,2600']
      set output: file_name
      set multiplot: 'layout 7,1'

      set grid: 'ytics mytics' # draw lines for each ytics and mytics
      set grid: 'xtics mytics' # draw lines for each ytics and mytics
      set mytics: 2
      set :grid
      # left
      t = []
      time_deltas = trajectory['left_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}

      position = trajectory['left_motor_points'].map {|e| e['p']}
      velocity = trajectory['left_motor_points'].map {|e| e['v']}
      acceleration = trajectory['left_motor_points'].map {|e| e['a']}


      tt, q, vq, aq = PositionSpline.qupsample(position, velocity, acceleration, time_deltas.map {|td| td / 1000.0}, DT)
      tt.map! {|t| t * 1000.0}

      set title: "trajectory #{n}, left motor position"
      set xrange: "[0:#{t.last.ceil(-3)}]"

      set yrange: "[#{[position.min.floor(-2), q.min.floor(-2)].min}:#{[position.max.ceil(-2), q.max.ceil(-2)].max}]"
      plot [t, position, with: 'lp', title: 'Left Motor position'], [tt, q, with: 'l', title: 'Left Motor real Position']

      set title: "trajectory #{n}, left motor velocity"
      set yrange: "[#{[velocity.min.floor(-2), vq.min.floor(-2)].min}:#{[velocity.max.ceil(-2), vq.max.ceil(-2)].max}]"
      plot [t, velocity, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Left Motor Velocity'], [tt, vq, with: 'l', title: 'Left Motor real Velocity']

      set title: "trajectory #{n}, left motor acceleration"
      set yrange: "[#{[acceleration.min.floor(-2), aq.min.floor(-2)].min}:#{[acceleration.max.ceil(-2), aq.max.ceil(-2)].max}]"
      plot [t, acceleration, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Left Motor Acceleration'], [tt, aq, with: 'l', title: 'Left Motor real Acceleration']

      ##########################################################
      #right
      ##########################################################

      set title: "trajectory #{n}, right motor position"
      t = []
      time_deltas = trajectory['right_motor_points'].map {|e| e['t']}
      time_deltas.size.times {|i| t << time_deltas[0..i].sum}
      position = trajectory['right_motor_points'].map {|e| e['p']}
      velocity = trajectory['right_motor_points'].map {|e| e['v']}
      acceleration = trajectory['right_motor_points'].map {|e| e['a']}

      tt, q, vq, aq = PositionSpline.qupsample(position, velocity, acceleration, time_deltas.map {|td| td / 1000.0}, DT)
      tt.map! {|t| t * 1000.0}

      set xrange: "[0:#{t.last.ceil(-3)}]"
      # set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"

      set yrange: "[#{[position.min.floor(-2), q.min.floor(-2)].min}:#{[position.max.ceil(-2), q.max.ceil(-2)].max}]"
      plot [t, position, with: 'l', title: 'Right Motor position'], [tt, q, with: 'l', title: 'Right Motor real Position']

      set title: "trajectory #{n}, right motor velocity"
      set yrange: "[#{[velocity.min.floor(-2), vq.min.floor(-2)].min}:#{[velocity.max.ceil(-2), vq.max.ceil(-2)].max}]"
      plot [t, velocity, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Right Motor Velocity'], [tt, vq, with: 'l', title: 'Right Motor real Velocity']

      set title: "trajectory #{n}, right motor acceleration"
      set yrange: "[#{[acceleration.min.floor(-2), aq.min.floor(-2)].min}:#{[acceleration.max.ceil(-2), aq.max.ceil(-2)].max}]"
      plot [t, acceleration, with: 'lp', pt: 7, pi: 1, ps: 0.5, title: 'Right Motor Acceleration'], [tt, aq, with: 'l', title: 'Right Motor real Acceleration']

      ##########################################################
      # figure
      ##########################################################
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
        point = Point.new(xx, yy)#.to_decart(width, dm, dy)
        x << point.x
        y << height - point.y
      end

      set xrange: "[0:#{width}]"
      set yrange: "[0:#{height}]"
      set size: 'ratio -1'
      set title: "trajectory #{n}, figure"
      unset :xlabel

      # plot [x[0..index - 1], y[0..index - 1], w: 'l', title: 'move-to'], [x[index + 1..-1], y[index + 1..-1], w: 'lp', pt: 7, pi: 1, ps: 0.2, title: 'paint']
      plot [x, y, w: 'l']
    end
  end

  def self.html(y:, x:, file_name: 'data.html')
    path = defined?(Dir.tmpdir) ? Dir.tmpdir << '/' << file_name : file_name

    Numo.gnuplot do
      reset
      unset :multiplot
      set ylabel: ''
      set autoscale: :fix
      # set xlabel: 'time, ms'
      set title: file_name

      set terminal: ['canvas', 'size 1200,800 mousing']
      set output: path
      # set style: 'func linespoints'
      # set multiplot: 'layout 4,1'

      set grid: 'ytics mytics' # draw lines for each ytics and mytics
      set grid: 'xtics mytics' # draw lines for each ytics and mytics
      set mytics: 2
      set :grid
      # left

      # set xrange: "[0:#{x.last.ceil(-2)}]"
      # set yrange: "[#{[velocity.min.floor(-2), position.min.floor(-2)].min}:#{[velocity.max.ceil(-2), position.max.ceil(-2)].max}]"
      # set arrow: "1 from 0,0 to #{t.last.ceil},0 nohead"

      plot x, y, w: 'lp', pt: 7, pi: 1, ps: 0.7
    end
    `open -a Safari #{path}`
  end


  def self.customer
    left_motor_points = [
        PVAT.new(360.0, 0, 0.0, 0),
        PVAT.new(360.0, 101.0, 0.0, 1000),
        PVAT.new(360.0, 101.0, 0.0, 10000),
        PVAT.new(360.0, 0.0, 0.0, 1000),
    ]

    right_motor_points = [
        PVAT.new(0, 0, 0.0, 0),
        PVAT.new(360.0, 100.0, 0.0, 1000),
        PVAT.new(720.0, 100.0, 0.0, 10000),
        PVAT.new(1080.0, 0.0, 0.0, 1000),
    ]

    t = Trajectory.new(left_motor_points, right_motor_points, 190)
    Plot.trajectory(n: 190, trajectory: JSON.parse(t.to_json))
  end


end
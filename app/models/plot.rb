require_relative 'array'
# require 'redis'
# require_relative 'config'
# require 'json'
# require 'numo/gnuplot'
# require_relative 'position_spline'

class Plot
  DT = 0.001

  def self.trajectory(n:, file_name: "#{n}.hmtl")
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

      set yrange: "[#{[position.min.floor(-2), q.min.floor(-2)].min}:#{[position.max.ceil(-2), q.max.ceil(-2)].max}]"
      plot [t, position, with: 'l', title: 'Left Motor position'], [tt, q, with: 'l', title: 'Left Motor real Position']

      set yrange: "[#{[velocity.min.floor(-2), vq.min.floor(-2)].min}:#{[velocity.max.ceil(-2), vq.max.ceil(-2)].max}]"
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

      set yrange: "[#{[position.min.floor(-2), q.min.floor(-2)].min}:#{[position.max.ceil(-2), q.max.ceil(-2)].max}]"
      plot [t, position, with: 'l', title: 'Right Motor position'], [tt, q, with: 'l', title: 'Right Motor real Position']

      set yrange: "[#{[velocity.min.floor(-2), vq.min.floor(-2)].min}:#{[velocity.max.ceil(-2), vq.max.ceil(-2)].max}]"
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

end
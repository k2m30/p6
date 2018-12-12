require_relative 'array'
# require 'redis'
# require_relative 'config'
# require 'json'
# require 'numo/gnuplot'
# require_relative 'position_spline'

class Plot
  DT = 0.001

  def self.trajectory(n:)
    s = Redis.new.get("#{Config.version}_#{n}")
    trajectory = JSON.parse(s, symbolize_names: true)
    left_p = trajectory[:left_motor_points].map {|t| t[:p]}
    left_v = trajectory[:left_motor_points].map {|t| t[:v]}
    a = Array[0] * left_v.size
    dts = trajectory[:left_motor_points].map {|t| t[:t] / 1000.0}

    t = dts.cumsum
    st, q, vq = PositionSpline.qupsample(left_p, left_v, a, dts, DT)

    html(x: t, y: left_p, file_name: "left_p_#{n}.html")
    Plot.html(x: st, y: q, file_name: "left_p_real_#{n}.html")

    html(x: t, y: left_v, file_name: "left_v_#{n}.html")
    Plot.html(x: st, y: vq, file_name: "left_v_real_#{n}.html")
    pp t.size
    pp st.size
    ########################
    right_p = trajectory[:right_motor_points].map {|t| t[:p]}
    right_v = trajectory[:right_motor_points].map {|t| t[:v]}
    a = Array[0] * right_v.size
    dts = trajectory[:right_motor_points].map {|t| t[:t] / 1000.0}
    t = dts.cumsum
    st, q, vq = PositionSpline.qupsample(right_p, right_v, a, dts, DT)

    html(x: t, y: right_p, file_name: "right_p_#{n}.html")
    Plot.html(x: st, y: q, file_name: "right_p_real_#{n}.html")

    html(x: t, y: right_v, file_name: "right_v_#{n}.html")
    Plot.html(x: st, y: vq, file_name: "right_v_real_#{n}.html")
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
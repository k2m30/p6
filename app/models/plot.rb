class Plot
  def self.html(y:, x:, file_name: './data.html')
    Numo.gnuplot do
      reset
      unset :multiplot
      set ylabel: ''
      set autoscale: :fix
      # set xlabel: 'time, ms'
      set title: file_name

      set terminal: ['canvas', 'size 1200,800 mousing']
      set output: "#{Dir.tmpdir << '/' << file_name}"
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
    `open -a Safari #{Dir.tmpdir << '/' << file_name}`
  end

end
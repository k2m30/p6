require 'csv'
require 'numo/gnuplot'
# require_relative 'plot'

class PositionSpline

  class << self
    def cumsum(array)
      array.inject([]) {|cs, n| cs << (cs.last || 0) + n}
    end

    def diff(array, dt)
      [0] +
          array.each_cons(2).map do |cur, nxt|
            (nxt - cur) / dt
          end
    end

    def trajectory(coeff, t_piece)
      y = []
      t_piece.each do |t|
        y << coeff[0] + coeff[1] * t + coeff[2] * t ** 2 + coeff[3] * t ** 3 + coeff[4] * t ** 4 + coeff[5] * t ** 5;
      end
      y
    end

    def spline_coeff(pf, vf, af, ps, vs, as, dt)
      a = []
      a[0] = ps
      a[1] = vs
      a[2] = as / 2
      a[3] = -(20 * ps - 20 * pf + 8 * dt * vf + 12 * dt * vs - af * dt ** 2 + 3 * as * dt ** 2) / (2 * dt ** 3)
      a[4] = (30 * ps - 30 * pf + 14 * dt * vf + 16 * dt * vs - 2 * af * dt ** 2 + 3 * as * dt ** 2) / (2 * dt ** 4)
      a[5] = -(12 * ps - 12 * pf + 6 * dt * vf + 6 * dt * vs - af * dt ** 2 + as * dt ** 2) / (2 * dt ** 5)
      a
    end

    def qupsample(p, v, a, t, dt)
      cs = cumsum(t)
      st = (0..cs.last).step(dt).to_a
      q = []

      p.zip(v, a, cs).each_cons(2) do |cur, nxt|
        coeff = spline_coeff(nxt[0], nxt[1], nxt[2], cur[0], cur[1], cur[2], nxt[3] - cur[3])
        t_piece = st.select {|el| el > cur[3] and el <= nxt[3]}.map {|el| el - cur[3]}
        q << trajectory(coeff, t_piece)
      end
      q.flatten!
      [st, q, diff(q, dt), diff(diff(q, dt), dt)]
    end

  end
end

# data = CSV.read('1.csv', headers: true, converters: :numeric, header_converters: :symbol)
# p = data[:p]#.map {|dp| dp * Math::PI / 180}
# v = data[:v]#.map {|dv| dv * Math::PI / 180}
# a = Array[0] * v.size
# t = data[:t].map {|dt| dt / 1000.0}
#
# dt = 0.01
#
# st, q, vq = PositionSpline.qupsample(p, v, a, t, dt)
# q#.map! {|q_rad| q_rad / Math::PI * 180.0}
# vq#.map! {|vq_rad| vq_rad / Math::PI * 180.0}
#
# Plot.html(x: st, y: q, file_name: 'p.html')
# Plot.html(x: st, y: vq, file_name: 'v.html')


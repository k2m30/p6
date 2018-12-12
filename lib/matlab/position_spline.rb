class PositionSpline

  def cumsum(a)
    a.inject([]) {|cs, n| cs << (cs.last || 0) + n}
  end

  def trajectory(t)
    coeff(pf, vf, af, ps, vs, as, dt)
    y = a[1] + a[2] * t + a[3] * t.** 2 + a[4] * t.** 3 + a[5] * t.** 4 + a[6] * t.** 5;
  end

  def coeff(pf, vf, af, ps, vs, as, dt)
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
    t = (0..t.max).step(dt).to_a
    q = Array[0] * t.size

    p.zip(v, a, t).each_cons(2) do |cur, nxt|
      coeff(cur[0], cur[1], cur[2], nxt[0], nxt[1], nxt[2], nxt[3] - cur[3])
    end

    ind = (t >= pt.t(k)) & (t < pt.t(k + 1))

    q(ind) = trj(a, t(ind) - pt.t(k))
  end

  return t, q
end

end
class Array
  def cumsum
    self.inject([]) {|cs, n| cs << (cs.last || 0) + n}
  end

  def diff(dt: 1.0)
    [0] +
        self.each_cons(2).map do |cur, nxt|
          (nxt - cur) / dt
        end
  end
end
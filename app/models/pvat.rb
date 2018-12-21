class PVAT
  attr_accessor :p, :v, :a, :t

  def initialize(p, v, a, t)
    # fail unless [p, v, t].all? {|e| e.is_a? Float}
    # fail if [p, v, t].any? {|e| e.nil?}
    @p = p
    @v = v
    @a = a
    @t = t
  end

  def to_s
    "[#{@p.round(1)}, #{@v.round(1)}, #{@a.round(1)}, #{@t.round(2)}] "
  end

  def inspect
    to_s
  end

  def self.from_json(json)
    new(json['p'], json['v'], json['a'], json['t'])
  end

end
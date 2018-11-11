class PVT
  attr_accessor :p, :v, :t

  def initialize(p, v, t)
    fail unless [p, v, t].all? {|e| e.is_a? Float}
    @p = p
    @v = v
    @t = t
  end

  def to_s
    "[#{@p}, #{@v}, #{@t}] "
  end

  def inspect
    to_s
  end

  def self.from_json(json)
    new(json['p'], json['v'], json['t'])
  end

end
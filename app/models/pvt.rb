class PVT
  attr_accessor :p, :v, :t

  def initialize(p, v, t)
    # fail unless [p, v, t].all? {|e| e.is_a? Float}
    # fail if [p, v, t].any? {|e| e.nil?}
    @p = p
    @v = v
    @t = t
  end

  def to_s
    "[#{@p.round(1)}, #{@v.round(1)}, #{@t.round(1)}] "
  end

  def inspect
    to_s
  end

  def self.from_json(json)
    new(json['p'], json['v'], json['t'])
  end

end
class Path
  attr_reader :d, :elements, :xml
  def initialize(path)
    @xml = path
    @d = path.attributes['d']
  end
end
class Layer
  attr_accessor :paths, :name, :xml

  def initialize(element)
    @paths = []
    @xml = element
    @name = element.attributes['id'].to_s
    element.traverse do |e|
      if e.name == 'path'
        d = e.attributes['d']
        paths = normalize_path(d)
        paths.each do |d|
          @paths.push Path.new(e, d)
        end
      end
    end
    optimize_paths
  end

  def optimize_paths

  end

  def normalize_path(d)
    paths = []
    begin
      m = / ?[Mm][^Mm]+/.match d
      paths.push m[0]
      d = m.post_match
    end while d.size > 0
    paths
  end

  def to_s
    @name
  end

  def inspect
    @name
  end
end
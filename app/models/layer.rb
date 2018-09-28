class Layer
  attr_accessor :paths, :name, :xml

  def initialize(element)
    @paths = []
    @xml = if element.is_a?(Nokogiri::XML::Element)
             element
           else
             Nokogiri::XML(element).elements.first
           end
    @name = @xml.attributes['id'].to_s
    @xml.traverse do |e|
      if e.name == 'path'
        d = e.attributes['d']
        paths = normalize_path(d)
        paths.each do |d|
          @paths.push Path.new(e, d)
        end
      end
    end
  end

  def self.build(layer_raw)
    redis = Redis.new
    layer = Layer.new(redis.get(layer_raw))

    splitted = []
    layer.paths.each do |path|
      splitted << path.split(Config.max_segment_length)
    end
    redis.set :splitted, splitted
  end

  def optimize_paths
    optimized_paths = []

    path = @paths.first
    until @paths.empty?
      optimized_paths.push path
      @paths.delete path
      closest = find_closest(path)
      @paths.delete closest
      path = closest
    end
    optimized_paths.push path
    @paths = optimized_paths.compact
  end

  def find_closest(path)
    distance = Float::INFINITY
    point = path.end_point
    closest = nil
    @paths.each do |p|
      next if p == path
      tmp_distance = [Point.distance(point, p.start_point), Point.distance(point, p.end_point)].min
      if distance > tmp_distance
        distance = tmp_distance
        closest = p
      end
    end
    Point.distance(point, closest.start_point) < Point.distance(point, closest.end_point) ? closest : closest.reverse!
    closest
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
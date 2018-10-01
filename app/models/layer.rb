class Layer
  attr_accessor :paths, :name, :xml, :splitted_paths

  def initialize(element)
    @xml = if element.is_a?(Nokogiri::XML::Element)
             element
           else
             Nokogiri::XML(element).elements.first
           end
    @name = @xml.attributes['id'].to_s

    @paths = []
    @xml.traverse do |e|
      if e.name == 'path'
        d = e.attributes['d']
        paths = normalize_path(d)
        paths.each do |d|
          @paths.push Path.new(e, d)
        end
      end
    end

    @color = @paths.first&.color
    @width = @paths.first&.width
    optimize_paths
    to_redis
  end

  def to_redis
    redis = Redis.new
    redis.set(@name, to_xml)
  end

  def self.from_redis(name)
    redis = Redis.new
    Layer.new(redis.get(name))
  end


  def self.build(layer_raw)
    layer = from_redis layer_raw
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

  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.g(id: @name, color: @color, width: @width) do
        break if @paths.empty?
        xml.style do
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}, stroke-linecap: round}"
        end
        @paths.each_with_index do |path, i|
          xml.path(d: path.d, id: "path_#{i}", class: 'd')
        end
      end
    end
    builder.to_xml
  end

  def to_svg(header)
    builder = Nokogiri::XML::Builder.new do |xml|
      #header and styles
      xml.doc.create_internal_subset(
          'svg',
          '-//W3C//DTD SVG 1.1//EN',
          'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
      )
      xml.svg(version: '1.1',
              xmlns: 'http://www.w3.org/2000/svg',
              'xmlns:xlink': 'http://www.w3.org/1999/xlink',
              x: header['x']&.to_s,
              y: header['y']&.to_s,
              width: '100%',
              height: '100%',
              viewBox: header['viewBox']&.to_s,
              preserveAspectRatio: 'xMinYMin meet',
              id: @name) do

        xml.style do
          xml.text ".move_to {stroke: #FF0000; fill-opacity: 0; stroke-width: #{(@width / 10).to_i}}\n"
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round}\n"
        end
        last_point = @paths.first.start_point
        @paths.each_with_index do |path, i|
          xml.path(d: "M#{last_point.x},#{last_point.y} L#{path.start_point.x},#{path.start_point.y}", class: 'move_to')
          xml.path(d: path.d, id: "path_#{i}", class: 'd')
          last_point = path.end_point
        end
      end
    end

    xml = builder.to_xml
    Redis.new.set @name, xml

    name = Rails.root.join('public', @name + '.svg')
    file = File.open(name, 'w')
    file.write xml
    file.close
    File.basename file.path
    xml
  end

  def inspect
    @name
  end
end
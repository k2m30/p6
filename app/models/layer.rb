class Layer
  attr_accessor :paths, :name, :xml, :splitted_paths, :color

  def initialize(element)
    @xml = if element.is_a?(Nokogiri::XML::Element)
             element
           else
             Nokogiri::XML(element).elements.first
           end
    @name = @xml.attributes['id'].to_s

    @paths = []
    @splitted_paths = []
    @xml.traverse do |e|
      if e.name == 'path' and e.attributes['class'].to_s != 'move_to'
        d = e.attributes['d']
        paths = normalize_path(d)
        paths.each do |d|
          @paths.push Path.new(e, d)
        end
      elsif e.name == 'spath'
        d = e.attributes['d']
        paths = normalize_path(d)
        paths.each do |d|
          @splitted_paths.push Path.new(e, d)
        end
      end
    end

    @color ||= @paths.first&.color || @xml.attributes['color']
    @width ||= @paths.first&.width || @xml.attributes['width']
    p @paths.size
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
    layer.splitted_paths = []
    layer.paths.each do |path|
      layer.splitted_paths << path.split(Config.max_segment_length)
    end
    # redis.set :splitted, layer.splitted_paths
    layer.to_redis
    layer
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
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round}\n"
          xml.text ".move_to {stroke: #FF0000; fill-opacity: 0; stroke-width: #{(@width.to_s.to_f / 10).to_i}}\n"
          xml.text ".s {stroke: #{@color}; fill-opacity: \"0.5\"; stroke-width: #{@width}; stroke-linecap: round}\n"
        end

        last_point = @paths.first.start_point
        @paths.each_with_index do |path, i|
          xml.path(d: "M#{last_point.x},#{last_point.y} L#{path.start_point.x},#{path.start_point.y}", class: 'move_to')
          xml.path(d: path.d, id: "path_#{i}", class: 'd')
          last_point = path.end_point
        end

        xml.g(id: :splitted, color: @color, width: @width) do
          @splitted_paths.each_with_index do |spath, i|
            xml.spath(d: spath.d, id: "spath_#{i}", class: 's')
          end
        end
      end
    end
    builder.to_xml
  end

  def to_svg(header)
    <<EOL
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="#{header['x']&.to_s}" y="#{header['y']&.to_s}" width="100%" height="100%" viewBox="#{header['viewBox']&.to_s}" preserveAspectRatio="xMinYMin meet" id="#{@name}">
    #{to_xml}
    </svg>
EOL
  end

  def write_svg(header)
    name = Rails.root.join('public', @name + '.svg')
    file = File.open(name, 'w')
    file.write to_svg(header)
    file.close
    File.basename file.path
  end

  def inspect
    @name
  end
end
class Layer
  attr_accessor :paths, :name, :xml, :splitted_paths, :tpaths, :color, :trajectories

  def initialize(name, paths, splitted_paths, tpaths, trajectories, color, width)
    @name = name
    @paths = paths
    @splitted_paths = splitted_paths
    @tpaths = tpaths
    @trajectories = trajectories
    @color = color
    @width = width
    to_redis unless Redis.new.get @name
  end

  def self.from_xml(element)
    @xml = element
    @name = @xml.attributes['id'].value

    @paths = []
    @splitted_paths = []
    @trajectories = []
    @tpaths = []
    Rack::MiniProfiler.step('Create paths') do
      @xml.css('path').each do |e|
        case e.attributes['class'].to_s
        when 'd', ''
          paths_array = Path.normalize_d(e.attributes['d'])
          paths_array.each do |d|
            @paths.push Path.from_str(d)
          end
        else
          fail 'Unrecognized class'
        end
      end
    end

    @color = @xml.at_css('path')&.attributes&.dig('stroke')&.value || @xml.attributes['color']&.value
    @width = @xml.at_css('path')&.attributes&.dig('stroke-width')&.value || @xml.attributes['width']&.value
    p [@name, @paths.size]
    new(@name, @paths, @splitted_paths, @tpaths, @trajectories, @color, @width)
  end

  def to_redis
    redis = Redis.new
    json = to_json
    redis.set(@name, json)
  end

  def self.from_redis(name)
    Rack::MiniProfiler.step('from redis') do
      redis = Redis.new
      Layer.from_json(JSON.parse(redis.get(name)))
    end
  end

  def self.from_json(json)
    Rack::MiniProfiler.step('from json') do
      @name = json['name']
      @paths = json['paths'].map {|path| Path.from_json(path)}
      @splitted_paths = json['splitted_paths'].map {|path| Path.from_json(path)}
      @tpaths = json['tpaths'].map {|path| Path.from_json(path)}
      # @trajectories = json['trajectories'].map {|trajectory| Trajectory.from_json(trajectory)}
      @color = json['color']
      @width = json['width']
      new(@name, @paths, @splitted_paths, @tpaths, @trajectories, @color, @width)
    end
  end

  def self.build(layer_raw)
    p 'build started'
    layer = from_redis layer_raw
    return layer if layer.paths.empty?
    layer.optimize_paths

    width = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy
    initial_point = Point.new(Config.initial_x, Config.initial_y).to_decart(width, dm, dy)
    layer.paths.first.elements.first.start_point = initial_point

    unless layer.paths.first.start_point == layer.paths.last.end_point
      layer.paths << Path.new([MoveTo.new([layer.paths.last.end_point, initial_point])])
    end

    layer.paths.each_cons(2) do |path_current, path_next|
      path_next.elements.first.start_point = path_current.elements.last.end_point
    end

    dl = Config.max_segment_length
    layer.splitted_paths = []
    layer.paths.each do |path|
      layer.splitted_paths << path.split(dl)
    end

    layer.tpaths = []
    layer.splitted_paths.each do |spath|
      layer.tpaths.push Path.make_tpath(spath, width, dm, dy)
    end

    Config.cleanup
    layer.build_trajectories

    fail if layer.paths.size != layer.splitted_paths.size or layer.tpaths.size != layer.trajectories.size or layer.splitted_paths.size != layer.tpaths.size

    layer.to_redis
    p 'build finished'
    layer
  end

  def build_trajectories
    Rack::MiniProfiler.step('build trajectories') do
      @trajectories = []
      Config.version += 1
      @splitted_paths.zip @tpaths do |spath, tpath|
        @trajectories.push Trajectory.build(spath, tpath)
      end
      redis = Redis.new
      prefix = Config.version
      @trajectories.each_with_index do |t, i|
        t.id = i
        redis.set "#{prefix}_#{t.id}", t.to_json
      end
      redis.del "#{prefix}_#{@trajectories.size}"
    end
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


  def to_xml
    p 'to_xml started'
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.g(id: @name, color: @color, width: @width) do
        break if @paths.empty?
        @width = @width.to_s.to_f
        xml.marker(id: 'arrow-end', markerWidth: @width, markerHeight: @width, refX: @width*1.5,refY: @width / 2, markerUnits: 'userSpaceOnUse', orient: 'auto') do
          xml.polyline(points: "0,0 #{@width},#{@width / 2} 0,#{@width} #{@width / 4},#{@width / 2} 0,0", 'stroke-width': 1, stroke: 'darkred', fill: 'red')
        end

        xml.circle(cx: Config.start_point.x, cy: Config.start_point.y, r: @width, fill: 'green', opacity: 0.5)

        xml.style do
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 1.0}\n"
          xml.text ".move_to {stroke: darkred; fill-opacity: 0; marker-end: url(#arrow-end); stroke-width: #{(@width / 5.0).to_i}}\n"
          xml.text ".s {stroke: #{@color}; fill-opacity: 0; stroke-width: #{(@width / 5.0).to_i}; stroke-linecap: round; opacity: 1.0} \n"
          xml.text ".t {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 1.0} \n"
        end

        xml.g(id: :main, color: @color, width: @width) do
          @paths.each_with_index do |path, i|
            xml.path(d: "M#{path.start_point.x},#{path.start_point.y} L#{path.elements.first.end_point.x},#{path.elements.first.end_point.y}", class: 'move_to')
            xml.path(d: path.d, id: "path_#{i}", class: 'd')
          end
        end

        xml.g(id: :splitted, color: @color, width: @width, style: 'display: none;') do
          @splitted_paths.each_with_index do |spath, i|
            xml.path(d: spath.d, id: "spath_#{i}", class: 's')
          end
        end

        xml.g(id: :tpath, color: @color, width: @width, style: 'display: none;') do
          @tpaths.each_with_index do |tpath, i|
            xml.path(d: tpath.d, id: "tpath_#{i}", class: 't')
          end
        end
        @trajectories ||= []
        xml.g(id: :trajectories) do
          @trajectories.each_with_index do |trajectory, i|
            xml.trajectory(id: "trajectory_#{i}", left: trajectory.left, right: trajectory.right)
          end
        end
      end
    end
    p 'to_xml finished'
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
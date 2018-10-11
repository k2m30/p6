class Layer
  attr_accessor :paths, :name, :xml, :splitted_paths, :tpaths, :color, :trajectories

  def initialize(element, lazy = true)
    r = nil
    Rack::MiniProfiler.step('Layer init') do
      @xml = Nokogiri::XML(element).elements.first
      @name = @xml.attributes['id'].to_s
      r = Redis.new.get(@name)
      @xml = Nokogiri::XML(r).elements.first if r and lazy
    end
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
        when 's'
          @splitted_paths.push Path.from_str(e.attributes['d'])
        when 't'
          @tpaths.push Path.from_str(e.attributes['d'])
        when 'move_to'
        else
          fail 'Unrecognized class'
        end
      end

      @xml.css('trajectory').each do |e|
        @trajectories.push Trajectory.from_str(e.attributes['left'], e.attributes['right'])
      end
    end

    @color = @xml.at_css('path')&.attributes&.dig('stroke') || @xml.attributes['color']
    @width = @xml.at_css('path')&.attributes&.dig('stroke-width') || @xml.attributes['width']
    p [@name, @paths.size]
    Rack::MiniProfiler.step("Optimize paths of #{@paths.size} elements") do
      optimize_paths unless r
    end
    Rack::MiniProfiler.step('Put to redis') do
      to_redis
    end
  end

  def to_redis
    redis = Redis.new
    xml = to_xml
    redis.set(@name, xml)
  end

  def self.from_redis(name)
    redis = Redis.new
    Layer.new(redis.get(name))
  end


  def self.build(layer_raw)
    p 'build started'
    layer = from_redis layer_raw

    width = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy
    layer.paths.first.elements.first.start_point = Point.new(Config.initial_x, Config.initial_y).to_decart(width, dm, dy)

    layer.splitted_paths = []
    dl = Config.max_segment_length

    layer.paths.each_cons(2) do |path_current, path_next|
      path_next.elements.first.start_point = path_current.elements.last.end_point
    end

    layer.paths.each do |path|
      layer.splitted_paths << path.split(dl)
    end

    layer.tpaths = []
    layer.trajectories = []
    layer.splitted_paths.each do |spath|
      tpath = TPath.new(spath, width, dm, dy)
      layer.tpaths.push tpath
      layer.trajectories.push Trajectory.build(spath, tpath)
    end

    fail if layer.paths.size != layer.splitted_paths.size or layer.tpaths.size != layer.trajectories.size or layer.splitted_paths.size != layer.tpaths.size

    layer.to_redis
    p 'build finished'
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


  def to_xml
    p 'to_xml started'
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.g(id: @name, color: @color, width: @width) do
        break if @paths.empty?
        xml.style do
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 1.0}\n"
          xml.text ".move_to {stroke: #FF0000; fill-opacity: 0; stroke-width: #{(@width.to_s.to_f / 5.0).to_i}}\n"
          xml.text ".s {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 0.0} \n"
          xml.text ".t {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 0.0} \n"
        end

        last_point = @paths.first.start_point
        @paths.each_with_index do |path, i|
          xml.path(d: "M#{last_point.x},#{last_point.y} L#{path.start_point.x},#{path.start_point.y}", class: 'move_to')
          xml.path(d: path.d, id: "path_#{i}", class: 'd')
          last_point = path.end_point
        end

        xml.g(id: :splitted, color: @color, width: @width) do
          @splitted_paths.each_with_index do |spath, i|
            xml.path(d: spath.d, id: "spath_#{i}", class: 's')
          end
        end

        xml.g(id: :tpath, color: @color, width: @width) do
          @tpaths.each_with_index do |tpath, i|
            xml.path(d: tpath.d, id: "tpath_#{i}", class: 't')
          end
        end

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
class Layer
  attr_accessor :paths, :name, :xml, :splitted_paths, :tpaths, :color, :trajectories, :total_time

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
    unless Rails.env.test?
      @splitted_paths = []
      @tpaths = []
      @trajectories = []
    end
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
      @splitted_paths = json['splitted_paths']
      # @splitted_paths = @splitted_paths.map {|path| Path.from_json(path)} unless @splitted_paths.blank?
      # @tpaths = json['tpaths'].map {|path| Path.from_json(path)}
      # @trajectories = json['trajectories'].map {|trajectory| Trajectory.from_json(trajectory)}
      @color = json['color']
      @width = json['width']
      new(@name, @paths, @splitted_paths, @tpaths, @trajectories, @color, @width)
    end
  end

  def self.build(name)
    layer = from_redis name
    return layer if layer.paths.empty?
    layer.paths.each {|path| path.move!(Config.move_x, Config.move_y)}

    layer.optimize_paths

    width = Config.canvas_size_x
    dm = Config.dm
    dy = Config.dy
    initial_point = Config.start_point.to_decart
    layer.paths.first.elements.first.start_point = initial_point
    # layer.paths[Config.start_from].elements.first.start_point = initial_point

    unless layer.paths.first.start_point == layer.paths.last.end_point
      layer.paths << Path.new([MoveTo.new([layer.paths.last.end_point, initial_point])])
    end

    layer.paths.each_cons(2) do |path_current, path_next|
      path_next.elements.first.start_point = path_current.elements.last.end_point
    end

    # puts "\nSplit paths:"
    # puts Benchmark.ms {
    dl = Config.max_segment_length
    layer.splitted_paths = []
    layer.paths.each do |path|
      # p path.d
      layer.splitted_paths << path.split(dl)
    end
    # }

    # puts "\nMake tpaths:"
    # puts Benchmark.ms {
    layer.tpaths = []
    layer.splitted_paths.each do |spath|
      layer.tpaths.push Path.make_tpath(spath, width, dm, dy)
    end
    # }
    Config.cleanup

    layer.build_trajectories
    layer.calculate_time

    fail if layer.paths.size != layer.splitted_paths.size or layer.tpaths.size != layer.trajectories.size or layer.splitted_paths.size != layer.tpaths.size
    layer.to_redis
    layer
  end

  def build_trajectories
    redis = Redis.new
    prefix = Config.version + 1
    start_from = Config.start_from.to_i
    Rack::MiniProfiler.step('build trajectories') do
      self.trajectories = []
      id = 0
      @splitted_paths.zip @tpaths do |spath, tpath|
        time = Benchmark.ms {
          if start_from == id
            point = Config.start_point
            spath.elements.first.start_point = point.to_decart
            tpath.elements.first.start_point = point
          end

          t = if id < start_from
                Trajectory.new([], [], id)
              else
                Trajectory.build(spath, tpath, id)
              end
          self.trajectories.push t
          redis.set "#{prefix}_#{t.id}", t.to_json
        }.to_s << ' #' << id.to_s
        puts time if Rails.env.development?
        id += 1
      end

      redis.del "#{prefix}_#{@trajectories.size}"
      Config.version += 1
      # Config.start_from = 0
    end
  end

  def optimize_paths
    optimized_paths = []

    path = find_closest(Config.start_point.to_decart)
    until @paths.empty?
      optimized_paths.push path
      @paths.delete path
      closest = find_closest(path.end_point)
      @paths.delete closest
      path = closest
    end
    optimized_paths.push path
    @paths = optimized_paths.compact
  end

  def find_closest(point)
    distance = Float::INFINITY
    closest = nil
    @paths.each do |p|
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
    builder = Nokogiri::XML::Builder.new do |xml|
      display_none = 'display: none;'

      xml.g(id: @name, color: @color, width: @width) do
        break if @paths.empty?
        @width = @width.to_s.to_f
        xml.marker(id: 'arrow-end', markerWidth: @width, markerHeight: @width, refX: @width * 1.5, refY: @width / 2, markerUnits: 'userSpaceOnUse', orient: 'auto') do
          xml.polyline(points: "0,0 #{@width},#{@width / 2} 0,#{@width} #{@width / 4},#{@width / 2} 0,0", 'stroke-width': 1, stroke: 'darkred', fill: 'red')
        end

        xml.marker(id: 's', markerWidth: @width / 4, markerHeight: @width / 4, refX: @width / 8, refY: @width / 8, markerUnits: 'userSpaceOnUse', orient: 'auto') do
          xml.circle(cx: @width / 8, cy: @width / 8, r: @width / 4, stroke: 'none', fill: 'darkred')
        end

        xml.circle(cx: Config.start_point.x, cy: Config.start_point.y, r: @width, fill: 'green', opacity: 0.4)
        xml.rect(x: Config.move_x, y: Config.move_y, width: [Config.crop_w, Config.canvas_size_x].max, height: [Config.crop_h, Config.canvas_size_y].max, 'fill-opacity': 0, 'stroke-width': @width, 'stroke-linecap': :round, opacity: 1.0, stroke: 'darkred')
        # xml.rect(x: Config.crop_x + Config.move_x, y: Config.crop_y + Config.move_y, width: Config.crop_w, height: Config.crop_h, 'fill-opacity': 0, 'stroke-width': @width, 'stroke-linecap': :round, opacity: 1.0, stroke: 'darkred')

        xml.style do
          xml.text ".d {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 1.0}\n"
          xml.text ".move_to {stroke: darkred; fill-opacity: 0; marker-end: url(#arrow-end); stroke-width: #{(@width / 5.0).to_i}}\n"
          # xml.text ".s {stroke: #{@color}; fill-opacity: 0; stroke-width: #{(@width / 4.0).to_i}; stroke-linecap: round; opacity: 1.0} \n"
          # xml.text ".t {stroke: #{@color}; fill-opacity: 0; stroke-width: #{@width}; stroke-linecap: round; opacity: 1.0} \n"
          xml.text "path.d:hover {stroke-width: #{@width * 1.5};} \n"
          xml.text ".invisible {visibility: hidden;}"
        end
        @splitted_paths ||= []

        xml.g(id: :main, color: @color, width: @width) do
          @paths.each_with_index do |path, i|
            xml.path(d: "M#{path.start_point.x},#{path.start_point.y} L#{path.elements.first.end_point.x},#{path.elements.first.end_point.y}", class: 'move_to', id: "move_to_#{i}")
            xml.path(d: path.d, id: "path_#{i}", class: 'd', onclick: "window.open('/trajectory?id=#{i}')")
          end
        end

        xml.circle(cx: Config.start_point.x, cy: Config.start_point.y, r: @width, fill: 'red', opacity: 1, id: 'current')

        # xml.g(id: :splitted, color: @color, width: @width, style: @splitted_paths.empty? ? display_none : '') do
        #   @splitted_paths.each_with_index do |spath, i|
        #     xml.path(d: "M#{spath.start_point.x},#{spath.start_point.y} L#{spath.elements.first.end_point.x},#{spath.elements.first.end_point.y}", class: 'move_to', id: "move_to_#{i}")
        #     xml.path(d: spath.d, id: "spath_#{i}", class: 's', onclick: "window.open('/trajectory?id=#{i}')")
        #   end
        # end

        # xml.g(id: :tpath, color: @color, width: @width, style: 'display: none;') do
        #   @tpaths.each_with_index do |tpath, i|
        #     xml.path(d: tpath.d, id: "tpath_#{i}", class: 't')
        #   end
        # end
        # @trajectories ||= []
        # xml.g(id: :trajectories) do
        #   @trajectories.each_with_index do |trajectory, i|
        #     xml.trajectory(id: "trajectory_#{i}", left: trajectory.left, right: trajectory.right)
        #   end
        # end
      end
    end
    builder.to_xml
  end

  def to_svg(header)
    x0, y0, x1, y1 = header['viewBox']&.to_s&.split&.map {|s| s.sub(',', '')}&.map(&:to_f)
    x1 = [x1, Config.canvas_size_x].max
    y1 = [y1, Config.canvas_size_y].max
    <<EOL
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" x="#{header['x']&.to_s}" y="#{header['y']&.to_s}" width="100%" height="100%" viewBox="#{x0}, #{y0}, #{x1}, #{y1}" preserveAspectRatio="xMinYMin meet" id="#{@name}">
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

  def calculate_time
    @total_time = 0
    current_point = Config.start_point.get_motors_deg
    acceleration = Config.max_angular_acceleration
    max_velocity = Config.max_angular_velocity

    @trajectories.each do |t|
      next if t.left_motor_points.empty? or t.right_motor_points.empty?
      from = current_point.x
      to = t.left_motor_points.first.p
      time_left = RRServoMotor.get_move_to_points(from: from, to: to, max_velocity: max_velocity, acceleration: acceleration).map(&:t).reduce(&:+) || 0

      from = current_point.y
      to = t.right_motor_points.first.p
      time_right = RRServoMotor.get_move_to_points(from: from, to: to, max_velocity: max_velocity, acceleration: acceleration).map(&:t).reduce(&:+) || 0

      @total_time += [time_left, time_right].max
      @total_time += t.total_time
      current_point = Point.new(t.left_motor_points.last.p, t.right_motor_points.last.p)
    end
    @total_time = (@total_time / 1000.0).round(1)
    p @total_time
    @total_time
  end

end
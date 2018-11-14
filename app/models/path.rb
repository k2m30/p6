class Path
  attr_reader :elements

  def initialize(elements)
    @elements = elements
  end

  def start_point
    @elements.first.start_point
  end

  def end_point
    @elements.last.end_point
  end

  # one path contains exactly one M command
  def self.normalize_d(d)
    paths = []
    begin
      m = / ?[Mm][^Mm]+/.match d
      paths.push m[0]
      d = m.post_match
    end while d.size > 0
    paths
  end

  def self.from_json(json)
    new(json['elements'].map {|e| Element.from_json e})
  end

  def self.from_str(d)
    s = d[/[a-y]/] or d[/[ABD-KN-Y]/] #no relative commands supported so far; M, L and C absolute commands only
    raise StandardError.new("Unsupported symbol \"#{s}\" in path \"#{d}\"") unless s.nil?
    d = d.dup
    str_elements = []
    elements = []
    begin
      m = / ?[MLCZz][^MLCZz]*/.match d
      str_elements.push m[0]
      d = m.post_match
    end while d.size > 0
    m = / ?(?<command>\w) ?(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+)/.match str_elements.first
    current_point = Point.new(m[:x], m[:y])
    str_elements.each do |d|
      case d[0]
      when 'M'
        elements.push MoveTo.from_str(current_point, d)
      when 'Z', 'z'
        elements.push Line.from_str(current_point, str_elements.first)
      when 'C'
        elements.push CubicCurve.from_str(current_point, d)
      when 'L'
        elements.push Line.from_str(current_point, d)
      else
        raise StandardError.new("Unsupported command \"#{d.first}\" in path \"#{d}\"")
      end
      current_point = elements.last.end_point
    end
    Path.new(elements)
  end

  def split(size)
    Path.new(@elements.map {|e| e.split(size)}.flatten)
  end

  def add_key_point(kl)
    current_length = 0
    @elements.each do |element|
      next if element.is_a? MoveTo
      fail 'add_key_points works with lines only' unless element.is_a? Line

      current_length += element.length

      if current_length == kl
        return
      elsif current_length > kl
        delta = (kl -(current_length - element.length)) / element.length
        index = @elements.index(element) + 1
        old_end_point = element.end_point.dup
        dx = element.end_point.x - element.start_point.x
        dy = element.end_point.y - element.start_point.y
        middle_point = Point.new(element.start_point.x + dx * delta, element.start_point.y + dy * delta)
        element.end_point = middle_point
        @elements.insert(index, Line.new([middle_point, old_end_point]))
        return
      end
    end
  end

  def self.make_tpath(path, width, dm, dy)
    tpath = path.deep_dup
    elements = []
    tpath.elements.each do |element|
      elements << element.inverse(width, dm, dy)
    end
    new(elements)
  end

  def get_time_points(v, a)
    time_points = [0.0]
    l = length
    l_current = 0.0

    t1 = v / a
    l1 = a * t1 ** 2 / 2

    l2 = l - 2 * l1
    t2 = l2 / v

    if l2 <= 0
      t1 = Math.sqrt(l / a)
      l1 = l / 2.0
      t2 = 0.0
      l2 = 0.0
    end

    @elements.each do |element|
      next if element.is_a? MoveTo

      l_current += element.length

      raise StandardError.new('Edge case') if 2 * l1 + l2 != l or l_current > l

      t = if l_current <= l1
            Math.sqrt(2 * l_current / a)
          elsif l_current > l1 and l_current <= (l1 + l2)
            t1 + (l_current - l1) / v
          elsif l_current > (l1 + l2)
            t1 + t2 + Math.sqrt(2 * (l_current - (l1 + l2)) / a)
          end
      time_points.push t
    end

    time_points
  end

  def get_idling_time(a, v)
    l = @elements.first.length
    t1 = v / a
    l1 = a * t1 ** 2 / 2

    l2 = l - 2 * l1
    t2 = l2 / v

    if l2 < 0
      return Math.sqrt(l / (2 * a))
    end
    raise StandardError.new('Edge case') if 2 * l1 + l2 != l
    2 * t1 + t2
  end

  def d
    d = ''
    @elements.each {|e| d << e.to_s}
    d
  end

  def size
    @elements.size
  end

  def to_s
    d
  end

  def length
    return @length unless @length.nil?
    @length = 0
    @elements.each do |e|
      @length += e.length unless e.is_a? MoveTo
    end
    @length
  end


  def reverse!
    elements = []
    elements.push MoveTo.new([end_point])
    until @elements.empty?
      elements.push @elements.pop.reverse!
    end
    elements.pop
    @elements = elements
  end

end
class Path
  attr_reader :elements, :xml, :color, :width, :opacity, :linecap

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

  def get_time_points(v, a)
    time_points = [0]
    l = length
    l_current = 0

    @elements.each do |element|
      next if element.is_a? MoveTo

      l_current += element.length
      t1 = v / a
      l1 = a * t1 ** 2 / 2

      l2 = l - 2 * l1
      t2 = l2 / v


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
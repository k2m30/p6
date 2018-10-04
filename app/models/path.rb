require_relative 'elements/cubic_curve'
require_relative 'elements/point'
require_relative 'elements/move_to'
require_relative 'elements/line'

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
    str_elements.each do |e|
      case e[0]
        when 'M'
          elements.push MoveTo.new(e, current_point)
        when 'Z', 'z'
          elements.push Line.new(str_elements.first, current_point)
        when 'C'
          elements.push CubicCurve.new(e, current_point)
        when 'L'
          elements.push Line.new(e, current_point)
        else
          raise StandardError.new("Unsupported command \"#{e.first}\" in path \"#{d}\"")
      end
      current_point = elements.last.end_point
    end
    Path.new(elements)
  end

  def split(size)
    Path.new(@elements.map{|e| e.split(size)}.flatten)
  end

  def d
    d = ''
    @elements.each { |e| d << e.to_s }
    d
  end

  def to_s
    "<path d=\"#{d}\" fill-opacity=\"0\" stroke=\"#{@color}\" stroke-width=\"#{@width}\" stroke-linecap=\"#{@linecap}\" class=\"d\"/>"
  end


  def reverse!
    elements = []
    elements.push MoveTo.new("M#{end_point.x},#{end_point.y} ", end_point)
    until @elements.empty?
      elements.push @elements.pop.reverse!
    end
    elements.pop
    @elements = elements
  end
end
require_relative 'elements/cubic_curve'
require_relative 'elements/point'
require_relative 'elements/move_to'
require_relative 'elements/line'

class Path
  attr_reader :elements, :xml, :color, :width, :opacity, :linecap

  def initialize(xml, str = nil)
    @xml = xml
    @elements = []
    build_elements(str || xml.attributes['d'])
    s = d[/[a-z]/] or d[/[ABD-KN-Z]/] #no relative commands supported so far; M, L and C absolute commands only
    raise StandardError.new("Unsupported symbol \"#{s}\" in path \"#{d}\"") unless s.nil?
    @color = xml.attributes['stroke']
    @width = xml.attributes['stroke-width']
    @opacity = xml.attributes['fill-opacity']
    @linecap = xml.attributes['stroke-linecap']
  end

  def start_point
    @elements.first.start_point
  end

  def end_point
    @elements.last.end_point
  end

  def build_elements(str)
    d = str.dup
    elements = []
    begin
      m = / ?[MLCZz][^MLCZz]*/.match d
      elements.push m[0]
      d = m.post_match
    end while d.size > 0
    m = / ?(?<command>\w) ?(?<x>[\d.-]+) ?, ?(?<y>[\d.-]+)/.match elements.first
    current_point = Point.new(m[:x], m[:y])
    elements.each do |e|
      case e[0]
        when 'M'
          @elements.push MoveTo.new(e, current_point)
        when 'Z', 'z'
          @elements.push Line.new(elements.first, current_point)
        when 'C'
          @elements.push CubicCurve.new(e, current_point)
        when 'L'
          @elements.push Line.new(e, current_point)
        else
          raise StandardError.new("Unsupported command \"#{e.first}\" in path \"#{d}\"")
      end
      current_point = @elements.last.end_point
    end
  end

  def split(size)
    xml = @xml.deep_dup
    xml.attributes['d'].value = @elements.map{|e| e.split(size)}.flatten.map(&:to_s).join
    Path.new(xml)
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
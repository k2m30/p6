require_relative 'elements/cubic_curve'
require_relative 'elements/point'
require_relative 'elements/move_to'
require_relative 'elements/line'

class Path
  attr_reader :d, :elements, :xml, :color, :width, :opacity, :start_point, :end_point

  def initialize(xml, d = nil)
    @xml = xml
    @d = d || xml.attributes['d']
    @elements = []
    build_elements
    s = @d[/[a-z]/] or @d[/[ABD-KN-Z]/] #no relative commands supported so far; M, L and C absolute commands only
    raise StandardError.new("Unsupported symbol \"#{s}\" in path \"#{@d}\"") unless s.nil?
    @color = xml.attributes['stroke']
    @width = xml.attributes['stroke-width'].to_s.to_f
    @opacity = xml.attributes['fill-opacity']
    @start_point = @elements.first.start_point
    @end_point = @elements.last.end_point
  end

  def build_elements
    d = @d.dup
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
          raise StandardError.new("Unsupported command \"#{e.first}\" in path \"#{@d}\"")
      end
      current_point = @elements.last.end_point
    end

    @d = ''
    @elements.each do |e|
      @d << e.to_s
    end
  end
end
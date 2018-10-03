class TPath
  def initialize(path)
    @tpath = path.deep_dup
    @elements = []
    @tpath.elements.each do |element|
      @elements << element.inverse
    end
  end

  def start_point
    @elements.first.start_point
  end

  def end_point
    @elements.last.end_point
  end

  def d
    d = ''
    @elements.each {|e| d << e.to_s}
    d
  end

  def to_s
    "<path d=\"#{d}\" fill-opacity=\"0\" stroke=\"#{@color}\" stroke-width=\"#{@width}\" stroke-linecap=\"#{@linecap}\" class=\"d\"/>"
  end

end
class Layer
  attr_accessor :paths, :name, :xml
  def initialize(element)
    @paths = []
    @xml = element
    @name = element.attributes['id']
    element.traverse do |e|
      if e.name == 'path'
        @paths.push Path.new(e)
      end
    end
  end

  def to_s
    @name
  end

  def inspect
    @name
  end
end
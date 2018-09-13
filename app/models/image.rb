class Image
  attr_reader :name, :path, :layers, :svg

  def initialize(name, path = Rails.root.join('public'))
    @name = name
    @path = path
    @svg = SVG.new(path, name)
    @layers = @svg.layers
  end
end
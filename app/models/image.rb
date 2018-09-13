class Image
  attr_reader :name, :path, :layers

  def initialize(name, path = Rails.root.join('app', 'assets', 'images'))
    @name = name
    @path = path
    @svg = SVG.new(path.join(name))
    @layers = @svg.layers
  end
end
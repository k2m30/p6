require_relative 'element'
class MoveTo < Element
  def initialize(points)
    @command_code = 'M'
    super
  end

  def reverse!
    self
  end

  def split(_)
    self
  end

end
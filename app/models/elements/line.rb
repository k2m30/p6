require_relative 'element'
class Line < Element
  def initialize(d, start_point = nil)
    @command_code = 'L'
    super
  end

  def to_s
    "#{@command_code}#{@end_point} "
  end
end
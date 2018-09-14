require_relative 'element'
class MoveTo < Element
  def initialize(d, start_point = nil)
    @command_code = 'M'
    super
  end

  def to_s
    "#{@command_code}#{@end_point} "
  end

end
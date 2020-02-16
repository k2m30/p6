require_relative 'rr_interface'

class RRInterfaceDummy < RRInterface
  def initialize
  end

  def start_motion(_ = nil)
  end
end
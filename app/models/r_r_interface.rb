require_relative 'r_r_servo_module'

class RRInterface
  attr_reader :handle

  def initialize(device)
    @handle = RRServoModule.rr_init_interface(device)
    raise "Error initializing USB-CAN interface \"#{device}\"" if @handle.null?
  end

  def deinitialize
    ret_code = RRServoModule.rr_deinit_interface(@handle)
    unless ret_code == RRServoModule::RET_OK
      raise "Interface error: #{ret_code}"
    end
  end

  def start_motion(delay = 0)
    RRServoModule.rr_start_motion(@handle, delay)
  end
end
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

  def log(file_name: './data', log_time:, position: true, velocity: false, current: false, set_point: false, motor_handles: [])
    return if motor_handles.empty?

    data = []
    start_time = Time.now.to_f
    while Time.now.to_f - start_time <= log_time
      begin
        motor_handles.each do |motor|
          motor_position = position ? motor.position : nil
          motor_set_point = set_point ? motor.position_set_point : nil
          motor_velocity = velocity ? self.velocity : nil
          motor_current = current ? self.current : nil
          motor_error = (position and set_point) ? motor_position - set_point : nil
          data << [motor_position,  motor_set_point, Time.now.to_f - start_time, motor_set_point, motor_error, motor_velocity, motor_current]
        end
      end

    end

    CSV.open(file_name + '.csv', 'wb') do |csv|
      data.each {|row| csv << row}
    end
  end

end
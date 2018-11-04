require_relative 'r_r_servo_module'
require_relative 'r_r_interface'

class RRServoMotor
  attr_accessor :id, :servo_handle

  def initialize(interface, servo_id = 123)
    @interface = interface
    @servo_handle = RRServoModule.rr_init_servo(@interface.handle, servo_id)
    set_state_operational unless state == RRServoModule::RR_NMT_OPERATIONAL
    @id = servo_id
  end

  def deinitialize
    ret_code = RRServoModule.rr_deinit_servo(@servo_handle)
    check_errors(ret_code)
  end

  def add_point(point)
    fail unless point.is_a? PVT
    add_motion_point(point.p, point.v, point.t)
  end

  def set_state_operational
    ret_code = RRServoModule.rr_servo_set_state_operational(@servo_handle)
    check_errors(ret_code)
  end

  def check_errors(ret_code)
    unless ret_code == RRServoModule::RET_OK
      raise "Error from motor #{@id}: #{RRServoMotor.get_error_value(ret_code)}"
    end
  end

  def soft_stop(time = 3000)
    clear_points_queue
    delta = velocity > 0 ? 90 : -90
    add_motion_point(position + delta, 0, time)
  end

  def go_to(position:, velocity: 80, acceleration: 86.479, time: 0)
    delta_position = (self.position - position).abs
    if time.zero?
      t1 = velocity / acceleration
      t2 = (delta_position - acceleration * t1 ** 2) / velocity
      t2 = 0 if t2 < 0
      time = t1 + t2
      time = (time * 1000).to_i * 2
    end
    clear_points_queue
    add_motion_point(position, 0, time)
    @interface.start_motion
  end

  def log_pvt(file_name, log_time)
    data = []
    start_time = Time.now.to_f
    while Time.now.to_f - start_time <= log_time
      begin
        current_position = position
        set_point = position_set_point
        twist = self.twist
        data << [current_position, Time.now.to_f - start_time, set_point, current_position - set_point, twist]
      end
    end

    CSV.open(file_name, 'wb') do |csv|
      data.each {|row| csv << row}
    end
  end

  def position=(pos)
    velocity = 180.0, current = 7.0
    # RRServoModule.rr_set_position_with_limits(@servo_handle, pos, velocity, current)
    RRServoModule.rr_set_position(@servo_handle, pos)
  end

  def state
    value_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret_code = RRServoModule.rr_servo_get_state(@servo_handle, value_ptr)
    check_errors(ret_code)
    value_ptr[0, Fiddle::SIZEOF_INT].unpack('C').first
  end

  def twist
    read_param RRServoModule::APP_PARAM_TORQUE
  end

  def position
    read_param RRServoModule::APP_PARAM_POSITION
  end

  def position_set_point
    read_param RRServoModule::APP_PARAM_CONTROLLER_POSITION_SETPOINT
  end

  def velocity
    read_param RRServoModule::APP_PARAM_VELOCITY
  end

  def temperature
    {actuator: read_param(RRServoModule::APP_PARAM_TEMPERATURE_ACTUATOR),
     electronics: read_param(RRServoModule::APP_PARAM_TEMPERATURE_ELECTRONICS)}
  end

  def read_param(param)
    value_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_FLOAT)
    ret_code = RRServoModule.rr_read_parameter(@servo_handle, param, value_ptr)
    check_errors(ret_code)

    value_ptr[0, Fiddle::SIZEOF_FLOAT].unpack('e').first
  end

  def read_cached_params
    @servo_handle[Fiddle::SIZEOF_VOIDP, Fiddle::SIZEOF_FLOAT * RRServoModule::APP_PARAM_SIZE].unpack("e#{RRServoModule::APP_PARAM_SIZE}")
  end

  def clear_points_queue
    ret_code = RRServoModule.rr_clear_points_all(@servo_handle)
    check_errors(ret_code)
  end

  def add_motion_point(point, velocity, time)
    ret_code = RRServoModule.rr_add_motion_point(@servo_handle, point, velocity, time)
    check_errors(ret_code)
  end

  def self.get_error_value(ret_code)
    ret_codes[ret_code]
  end

  def self.ret_codes
    RRServoModule.constants.select {|e| e.to_s.include?('RET')}
  end
end

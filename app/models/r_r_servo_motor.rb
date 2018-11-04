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
    fail 'Point is not of PVT type' unless point.is_a? PVT
    add_motion_point(point.p, point.v, point.t)
  end

  def go_to(pos:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    current_position = position
    l = pos - current_position
    sign = l <=> 0
    sign = 1 if sign.zero?

    t1 = max_velocity / acceleration
    l1 = acceleration * t1 ** 2 / 2

    l2 = l.abs - 2 * l1
    t2 = l2 / max_velocity

    if l2 <= 0
      t1 = Math.sqrt(l.abs / acceleration)
      add_motion_point(current_position + sign * l.abs / 2, t1 * acceleration * sign, t1 * 1000)
      add_motion_point(pos, 0, t1 * 2 * 1000)
      t2 = 0
    else
      p [position, velocity.round(2), 0.0]

      add_motion_point(current_position + sign * l1, max_velocity * sign, t1 * 1000)
      p [current_position + sign * l1, max_velocity * sign, t1 * 1000]

      add_motion_point(current_position + sign * (l1 + l2), max_velocity * sign, t2 * 1000)
      p [current_position + sign * (l1 + l2), max_velocity * sign, t2 * 1000]

      add_motion_point(pos, 0, t1 * 1000)
      p [pos, 0, t1 * 1000]

    end
    @interface.start_motion if start_immediately
    t1 + t2 + t1
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

  def log_pvt(file_name = './data.csv', log_time)
    data = []
    start_time = Time.now.to_f
    while Time.now.to_f - start_time <= log_time
      begin
        current_position = position
        set_point = position_set_point
        # twist = self.twist
        velocity = self.velocity
        data << [current_position, Time.now.to_f - start_time, set_point, current_position - set_point, velocity]
      end
    end

    CSV.open(file_name, 'wb') do |csv|
      data.each {|row| csv << row}
    end
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

  def wait_for_motion_is_finished
    loop {break if velocity.round(2).zero?}
  end
end

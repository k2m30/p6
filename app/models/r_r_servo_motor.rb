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

  def queue_size
    value_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret_code = RRServoModule.rr_get_points_size(@servo_handle, value_ptr)
    check_errors(ret_code)
    value_ptr[0, Fiddle::SIZEOF_INT].unpack('C').first
  end

  def get_errors
    errors_count = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    errors_array = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT * RRServoModule::ARRAY_ERROR_BITS_SIZE)
    ret_code = RRServoModule.rr_read_error_status(@servo_handle, errors_count, errors_array)


    errors_count = errors_count[0, Fiddle::SIZEOF_INT].unpack('C').first

    errors_count.times do |i|
      puts RRServoModule.rr_describe_emcy_bit(errors_array[i])
    end

    check_errors(ret_code)
    ret_code
  end

  def calculate_time(start_position:, start_velocity:, start_acceleration: 0, start_time: 0, end_position:, end_velocity:, end_acceleration: 0, end_time: 0)
    time_ms = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret_code = RRServoModule.rr_invoke_time_calculation(@servo_handle, start_position, start_velocity, start_acceleration, start_time, end_position, end_velocity, end_acceleration, end_time, time_ms)
    check_errors(ret_code)

    time_ms[0, Fiddle::SIZEOF_FLOAT].unpack('C').first
  end

  def self.get_move_to_points(from:, to:, max_velocity: 180.0, acceleration: 250.0)
    l = to - from
    sign = l <=> 0
    sign = 1 if sign.zero?

    t1 = max_velocity / acceleration
    l1 = acceleration * t1 ** 2 / 2

    l2 = l.abs - 2 * l1
    t2 = l2 / max_velocity

    if l2 <= 0
      k = 0.9 # make trapezium out of the triangle
      t1 = Math.sqrt(l.abs / acceleration)
      tsq = t1 / k - t1
      tt = t1 - tsq
      l1 = acceleration * tt ** 2 / 2
      l2 = l.abs - 2 * l1
      t1 = tt
      t2 = 2 * tsq
    else
      k = 1.0
    end
    points = [PVT.new(from, 0, 0)]
    points << PVT.new(from + sign * l1, max_velocity * k * sign, t1 * 1000)
    points << PVT.new(from + sign * (l1 + l2), max_velocity * k * sign, t2 * 1000)
    points << PVT.new(to, 0, t1 * 1000)
    points
  end

  def go_to(pos:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    RRServoMotor.get_move_to_points(
        from: position, to: pos, max_velocity: max_velocity, acceleration: acceleration
    ).each(&method(:add_point))
    @interface.start_motion if start_immediately
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

  def soft_stop
    clear_points_queue
    self.velocity = 0.0
  end

  def log_pvt(file_name = './data.csv', log_time)
    data = []
    start_time = Time.now.to_f
    while Time.now.to_f - start_time <= log_time
      begin
        current_position = position
        set_point = position_set_point
        current = self.current
        velocity = self.velocity
        data << [current_position, Time.now.to_f - start_time, set_point, current_position - set_point, velocity, current]
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

  def velocity=(v)
    ret_code = RRServoModule.rr_set_velocity(@servo_handle, v)
    check_errors(ret_code)
  end

  def current
    read_param RRServoModule::APP_PARAM_CURRENT_INPUT
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

require_relative 'rr_servo_module'
require_relative 'rr_interface'

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
    return [] if sign.zero?

    velocity_spline = VelocitySpline.create(length: (to - from).abs, max_linear_velocity: max_velocity, linear_acceleration: acceleration)

    dt = [velocity_spline.time_points.last / 100.0, 0.2].max
    t = (0..velocity_spline.time_points.last).step(dt)
    v = velocity_spline.get(t)
    p = [0]
    deltas = [0]
    v.zip(t).each_cons(2) do |cur, nxt|
      t_delta = (nxt[1] - cur[1])
      deltas << t_delta
      p << (nxt[0] + cur[0]) / 2 * t_delta + p.last
    end

    points = []
    p.zip(v, deltas).each do |position, velocity, time|
      points << PVT.new(from + sign * position, velocity * sign, time * 1000.0)
    end

    points
  end

  def go_to(pos:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    RRServoMotor.get_move_to_points(
        from: position, to: pos, max_velocity: max_velocity, acceleration: acceleration
    )[1..-1].each do |point|
      add_point(point)
    end
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

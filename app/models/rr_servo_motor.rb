require_relative 'rr_servo_module'
require_relative 'rr_interface'
require_relative 'velocity_spline'

class RetError < StandardError;
end
class WrongTrajectoryError < StandardError;
end

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
    fail 'Point is not of PVAT type' unless point.is_a? PVAT
    add_motion_point(point.p, point.v, point.a, point.t)
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
    return [] if to == from

    velocity_spline = VelocitySpline.new(length: (to - from).abs, max_linear_velocity: max_velocity, linear_acceleration: acceleration)
    dt = VelocitySpline::STEP
    begin
      points = velocity_spline.pvat_points(dt: dt)
      dt = dt *1.5
    end while points.size > 200

    points.each do |point|
      point.p = from + sign * point.p
      point.v *= sign
      point.a *= sign
    end
    points
  end

  def move(from: nil, to:, max_velocity: 180.0, acceleration: 250.0, start_immediately: false)
    from ||= position
    points = RRServoMotor.get_move_to_points(
        from: from, to: to, max_velocity: max_velocity, acceleration: acceleration
    )
    # t = Trajectory.new(points[0..30], points[0..30], 100)
    # Plot.trajectory(trajectory: t, n: 100)
    return 0 if points.empty?

    points[1..-1].each do |point|
      begin
        add_point(point)
      rescue RetError
        puts "RET_ERROR on #{@id}, move_to"
        retry
      rescue WrongTrajectoryError => e
        t = Trajectory.new(points, points, 1000)
        Plot.trajectory(trajectory: t, n: 1000)
        fail WrongTrajectoryError, e
      end
    end
    @interface.start_motion if start_immediately
    points.map(&:t).reduce(&:+)
  end

  def set_state_operational
    ret_code = RRServoModule.rr_servo_set_state_operational(@servo_handle)
    check_errors(ret_code)
  end

  def set_position(position, velocity: 120, acceleration: 250)
    value_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
    ret_code = RRServoModule.rr_set_position_with_limits(@servo_handle, position, velocity, acceleration, value_ptr)
    check_errors(ret_code)
    value_ptr[0, Fiddle::SIZEOF_INT].unpack('C').first
  end

  def check_errors(ret_code)
    unless ret_code == RRServoModule::RET_OK
      case ret_code
      when RRServoModule::RET_ERROR
        raise RetError, "Ret Error from motor #{@id}: #{RRServoMotor.get_error_value(ret_code)}"
      when RRServoModule::RET_WRONG_TRAJ
        raise WrongTrajectoryError, "Wrong trajectory from motor #{@id}: #{RRServoMotor.get_error_value(ret_code)}"
      else
        raise "Error from motor #{@id}: #{RRServoMotor.get_error_value(ret_code)}"
      end
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
      data.each { |row| csv << row }
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

  def add_motion_point(point, velocity, acceleration, time)
    ret_code = RRServoModule.rr_add_motion_point_pvat(@servo_handle, point, velocity, acceleration, time)
    check_errors(ret_code)
  end

  def self.get_error_value(ret_code)
    ret_codes[ret_code]
  end

  def self.ret_codes
    RRServoModule.constants.select { |e| e.to_s.include?('RET') }
  end
end

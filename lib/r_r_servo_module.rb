require 'fiddle'
require 'fiddle/import'

module RRServoModule
  extend Fiddle::Importer
  dlload './libservo_api.so'
  typealias 'rr_ret_status_t', 'int'
  typealias 'rr_servo_param_t', 'int'
  typealias 'rr_nmt_state_t', 'int'
  typealias 'rr_nmt_cb_t', 'void *'
  typealias 'rr_emcy_cb_t', 'void *'
  typealias 'uint8_t', 'int'
  typealias 'uint16_t', 'int'
  typealias 'uint32_t', 'int'
  typealias 'bool', 'int'

  RET_OK = 0
  RET_ERROR = 1
  RET_BAD_INSTANCE = 2
  RET_BUSY = 3
  RET_WRONG_TRAJ = 4
  RET_LOCKED = 5
  RET_STOPPED = 6
  RET_TIMEOUT = 7
  RET_ZERO_SIZE = 8
  RET_SIZE_MISMATCH = 9
  RET_WRONG_ARG = 10
#
  APP_PARAM_NULL = 0
  APP_PARAM_POSITION = 1
  APP_PARAM_VELOCITY = 2
  APP_PARAM_POSITION_ROTOR = 3
  APP_PARAM_VELOCITY_ROTOR = 4
  APP_PARAM_POSITION_GEAR_360 = 5
  APP_PARAM_POSITION_GEAR_EMULATED = 6
  APP_PARAM_CURRENT_INPUT = 7
  APP_PARAM_CURRENT_OUTPUT = 8
  APP_PARAM_VOLTAGE_INPUT = 9
  APP_PARAM_VOLTAGE_OUTPUT = 10
  APP_PARAM_CURRENT_PHASE = 11
  APP_PARAM_TEMPERATURE_ACTUATOR = 12
  APP_PARAM_TEMPERATURE_ELECTRONICS = 13
  APP_PARAM_TORQUE = 14
  APP_PARAM_ACCELERATION = 15
  APP_PARAM_ACCELERATION_ROTOR = 16
  APP_PARAM_CURRENT_PHASE_1 = 17
  APP_PARAM_CURRENT_PHASE_2 = 18
  APP_PARAM_CURRENT_PHASE_3 = 19
  APP_PARAM_CURRENT_RAW = 20
  APP_PARAM_CURRENT_RAW_2 = 21
  APP_PARAM_CURRENT_RAW_3 = 22
  APP_PARAM_ENCODER_MASTER_TRACK = 23
  APP_PARAM_ENCODER_NONIUS_TRACK = 24
  APP_PARAM_ENCODER_MOTOR_MASTER_TRACK = 25
  APP_PARAM_ENCODER_MOTOR_NONIUS_TRACK = 26
  APP_PARAM_TORQUE_ELECTRIC_CALC = 27
  APP_PARAM_CONTROLLER_VELOCITY_ERROR = 28
  APP_PARAM_CONTROLLER_VELOCITY_SETPOINT = 29
  APP_PARAM_CONTROLLER_VELOCITY_FEEDBACK = 30
  APP_PARAM_CONTROLLER_VELOCITY_OUTPUT = 31
  APP_PARAM_CONTROLLER_POSITION_ERROR = 32
  APP_PARAM_CONTROLLER_POSITION_SETPOINT = 33
  APP_PARAM_CONTROLLER_POSITION_FEEDBACK = 34
  APP_PARAM_CONTROLLER_POSITION_OUTPUT = 35
  APP_PARAM_CONTROL_MODE = 36
  APP_PARAM_FOC_ANGLE = 37
  APP_PARAM_FOC_IA = 38
  APP_PARAM_FOC_IB = 39
  APP_PARAM_FOC_IQ_SET = 40
  APP_PARAM_FOC_ID_SET = 41
  APP_PARAM_FOC_IQ = 42
  APP_PARAM_FOC_ID = 43
  APP_PARAM_FOC_IQ_ERROR = 44
  APP_PARAM_FOC_ID_ERROR = 45
  APP_PARAM_FOC_UQ = 46
  APP_PARAM_FOC_UD = 47
  APP_PARAM_FOC_UA = 48
  APP_PARAM_FOC_UB = 49
  APP_PARAM_FOC_U1 = 50
  APP_PARAM_FOC_U2 = 51
  APP_PARAM_FOC_U3 = 52
  APP_PARAM_FOC_PWM1 = 53
  APP_PARAM_FOC_PWM2 = 54
  APP_PARAM_FOC_PWM3 = 55
  APP_PARAM_FOC_TIMER_TOP = 56
  APP_PARAM_DUTY = 57
  APP_PARAM_SIZE = 58
#
  RR_NMT_INITIALIZING = 0
  RR_NMT_BOOT = 2
  RR_NMT_PRE_OPERATIONAL = 127
  RR_NMT_OPERATIONAL = 5
  RR_NMT_STOPPED = 4
  RR_NMT_HB_TIMEOUT = -1
#
  extern 'void rr_sleep_ms(int ms)'
  extern 'rr_ret_status_t rr_write_raw_sdo(rr_servo_t *servo, uint16_t idx, uint8_t sidx, uint8_t *data, int sz, int retry, int tout)'
  extern 'rr_ret_status_t rr_read_raw_sdo(rr_servo_t *servo, uint16_t idx, uint8_t sidx, uint8_t *data, int *sz, int retry, int tout)'
  extern 'void rr_set_debug_log_stream(FILE *f)'
  extern 'void rr_set_comm_log_stream(rr_can_interface_t *interface, FILE *f)'
  extern 'void rr_setup_nmt_callback(rr_can_interface_t *interface, rr_nmt_cb_t cb)'
  extern 'void rr_setup_emcy_callback(rr_can_interface_t *interface, rr_emcy_cb_t cb)'
  extern 'char *rr_describe_nmt(rr_nmt_state_t state)'
  extern 'char *rr_describe_emcy_code(uint16_t code)'
  extern 'char *rr_describe_emcy_bit(uint8_t bit)'
  extern 'rr_can_interface_t *rr_init_interface(char *interface_name)'
  extern 'rr_ret_status_t rr_deinit_interface(rr_can_interface_t **interface)'
  extern 'rr_servo_t *rr_init_servo(rr_can_interface_t *interface, uint8_t id)'
  extern 'rr_ret_status_t rr_deinit_servo(rr_servo_t **servo)'
  extern 'rr_ret_status_t rr_servo_reboot(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_servo_reset_communication(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_servo_set_state_operational(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_servo_set_state_pre_operational(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_servo_set_state_stopped(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_net_reboot(rr_can_interface_t *interface)'
  extern 'rr_ret_status_t rr_net_reset_communication(rr_can_interface_t *interface)'
  extern 'rr_ret_status_t rr_net_set_state_operational(rr_can_interface_t *interface)'
  extern 'rr_ret_status_t rr_net_set_state_pre_operational(rr_can_interface_t *interface)'
  extern 'rr_ret_status_t rr_net_set_state_stopped(rr_can_interface_t *interface)'
  extern 'rr_ret_status_t rr_net_get_state(rr_can_interface_t *interface, int id, rr_nmt_state_t *state)'
  extern 'rr_ret_status_t rr_servo_get_state(rr_servo_t *servo, rr_nmt_state_t *state)'
  extern 'rr_ret_status_t rr_release(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_freeze(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_brake_engage(rr_servo_t *servo, bool en)'
  extern 'rr_ret_status_t rr_set_current(rr_servo_t *servo, float current_a)'
  extern 'rr_ret_status_t rr_set_velocity(rr_servo_t *servo, float velocity_deg_per_sec)'
  extern 'rr_ret_status_t rr_set_velocity_motor(rr_servo_t *servo, float velocity_rpm)'
  extern 'rr_ret_status_t rr_set_position(rr_servo_t *servo, float position_deg)'
  extern 'rr_ret_status_t rr_set_velocity_with_limits(rr_servo_t *servo, float velocity_deg_per_sec, float current_a)'
  extern 'rr_ret_status_t rr_set_position_with_limits(rr_servo_t *servo, float position_deg, float velocity_deg_per_sec, float current_a)'
  extern 'rr_ret_status_t rr_set_duty(rr_servo_t *servo, float duty_percent)'
  extern 'rr_ret_status_t rr_add_motion_point(rr_servo_t *servo, float position_deg, float velocity_deg, uint32_t time_ms)'
  extern 'rr_ret_status_t rr_add_motion_point_pvat( rr_servo_t *servo, float position_deg, float velocity_deg_per_sec, float accel_deg_per_sec2, uint32_t time_ms)'
  extern 'rr_ret_status_t rr_start_motion(rr_can_interface_t *interface, uint32_t timestamp_ms)'
  extern 'rr_ret_status_t rr_read_error_status(rr_servo_t *servo, uint32_t *error_count, uint8_t *error_array)'
  extern 'rr_ret_status_t rr_param_cache_update(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_param_cache_setup_entry(rr_servo_t *servo, rr_servo_param_t param, bool enabled)'
  extern 'rr_ret_status_t rr_read_parameter(rr_servo_t *servo, rr_servo_param_t param, float *value)'
  extern 'rr_ret_status_t rr_read_cached_parameter(rr_servo_t *servo, rr_servo_param_t param, float *value)'
  extern 'rr_ret_status_t rr_clear_points_all(rr_servo_t *servo)'
  extern 'rr_ret_status_t rr_clear_points(rr_servo_t *servo, uint32_t num_to_clear)'
  extern 'rr_ret_status_t rr_get_points_size(rr_servo_t *servo, uint32_t *num)'
  extern 'rr_ret_status_t rr_get_points_free_space(rr_servo_t *servo, uint32_t *num)'
  extern 'rr_ret_status_t rr_invoke_time_calculation(rr_servo_t *servo, float start_position_deg, float start_velocity_deg, float start_acceleration_deg_per_sec2, uint32_t start_time_ms, float end_position_deg, float end_velocity_deg, float end_acceleration_deg_per_sec2, uint32_t end_time_ms, uint32_t *time_ms)'
  extern 'rr_ret_status_t rr_set_zero_position(rr_servo_t *servo, float position_deg)'
  extern 'rr_ret_status_t rr_set_zero_position_and_save(rr_servo_t *servo, float position_deg)'
  extern 'rr_ret_status_t rr_get_max_velocity(rr_servo_t *servo, float *velocity_deg_per_sec)'
  extern 'rr_ret_status_t rr_set_max_velocity(rr_servo_t *servo, float max_velocity_deg_per_sec)'
  extern 'rr_ret_status_t rr_change_id_and_save(rr_can_interface_t *interface, rr_servo_t *servo, uint8_t new_can_id)'
  extern 'rr_ret_status_t rr_get_hardware_version(rr_servo_t *servo, char *version_string, int *version_string_size)'
  extern 'rr_ret_status_t rr_get_software_version(rr_servo_t *servo, char *version_string, int *version_string_size)'
  def self.build_methods(file_name)
    functions = []
    blacklist = %w[extern typedef]
    text = File.open(file_name, 'rt').read.split "\n"
    text.each_with_index do |l, i|
      next if l[/^\w+/].nil?

      next if blacklist.any? {|word| l.include? word}

      until l.include? ';'
        next_line = text[i + 1]
        l << next_line

        text.delete next_line
      end
      l = l.gsub('const ', '')
      functions << l
    end

    functions.each do |f|
      puts "extern '#{f.gsub(/\s{2,}/, ' ').delete(';')}'"
    end
  end

  def self.build_constants(file_name)
    lines = File.open(file_name, 'rt').readlines

    until lines.empty?
      line = lines.shift
      if line.include? 'enum'
        line = lines.shift
        i = 0
        until line.include?('}')
          line = lines.shift
          const_name = line[/[[:upper:]_0-9]+/]
          next if const_name.nil? || (const_name.size <= 1)

          # puts "const_set('#{const_name}', #{/=\s+(?<value>-?\d+)/.match(line)&.send(:[], :value) || i})"
          puts "#{const_name} = #{/=\s+(?<value>-?\d+)/.match(line)&.send(:[], :value) || i}"
          i += 1
        end
        puts('#')
      end
    end
  end

  def self.build_module_names(file_name = './api.h')
    build_constants(file_name)
    build_methods(file_name)
  end
end

# RRServoModule.build_module_names

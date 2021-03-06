require 'yaml'
require_relative 'point'

class Config
  class << self

    def redis
      @redis ||= Redis.new
    end

    def linear_velocity
      get_value('linear_velocity')
    end

    def linear_velocity=(value)
      set_value('linear_velocity', value)
    end

    def idling_velocity
      get_value('idling_velocity')
    end

    def idling_velocity=(value)
      set_value('idling_velocity', value)
    end

    def linear_acceleration
      get_value('linear_acceleration')
    end

    def linear_acceleration=(value)
      set_value('linear_acceleration', value)
    end

    def max_angular_velocity
      get_value('max_angular_velocity')
    end

    def max_angular_velocity=(value)
      set_value('max_angular_velocity', value)
    end

    def max_angular_acceleration
      get_value('max_angular_acceleration')
    end

    def max_angular_acceleration=(value)
      set_value('max_angular_acceleration', value)
    end

    def max_segment_length
      get_value('max_segment_length')
    end

    def max_segment_length=(value)
      set_value('max_segment_length', value)
    end

    def motor_pulley_diameter
      get_value('motor_pulley_diameter')
    end

    def motor_pulley_diameter=(value)
      set_value('motor_pulley_diameter', value)
    end

    def initial_x
      get_value('initial_x')
    end

    def initial_x=(value)
      set_value('initial_x', value)
    end

    def initial_y
      get_value('initial_y')
    end

    def initial_y=(value)
      set_value('initial_y', value)
    end

    def crop_x
      get_value('crop_x')
    end

    def crop_x=(value)
      set_value('crop_x', value)
    end

    def crop_y
      get_value('crop_y')
    end

    def crop_y=(value)
      set_value('crop_y', value)
    end

    def crop_w
      get_value('crop_w')
    end

    def crop_w=(value)
      set_value('crop_w', value)
    end

    def crop_h
      get_value('crop_h')
    end

    def crop_h=(value)
      set_value('crop_h', value)
    end

    def move_x
      get_value('move_x')
    end

    def move_x=(value)
      set_value('move_x', value)
    end

    def move_y
      get_value('move_y')
    end

    def move_y=(value)
      set_value('move_y', value)
    end

    def max_spray_length
      get_value('max_spray_length')
    end

    def max_spray_length=(value)
      set_value('max_spray_length', value)
    end

    def canvas_size_x
      get_value('canvas_size_x')
    end

    def canvas_size_x=(value)
      set_value('canvas_size_x', value)
    end

    def canvas_size_y
      get_value('canvas_size_y')
    end

    def canvas_size_y=(value)
      set_value('canvas_size_y', value)
    end

    def dm
      get_value('dm')
    end

    def dm=(value)
      set_value('dm', value)
    end

    def dy
      get_value('dy')
    end

    def dy=(value)
      set_value('dy', value)
    end

    def simulation_velocity
      get_value('simulation_velocity')
    end

    def simulation_velocity=(value)
      set_value('simulation_velocity', value)
    end

    def image_name
      get_value('image_name')
    end

    def image_name=(value)
      set_value('image_name', value)
    end

    def version
      get_value('version')
    end

    def version=(value)
      set_value('version', value)
    end

    def start_from
      get_value('start_from')
    end

    def start_from=(value)
      set_value('start_from', value)
    end

    #################################################

    def file_name
      Rails.root.join('config', 'config.yml') rescue local? ? '/Users/user/projects/p6/config/config.yml' : '/home/pi/p6/config/config.yml'
    end

    def start_point
      Point.new(initial_x, initial_y)
    end

    def keys
      YAML.load(File.open(file_name)).keep_if {|_, v| v['hidden'].nil?}.keys
    end

    def description(name)
      YAML::load_file(file_name)[name]['description']
    end

    def build_names
      YAML.load(File.open(file_name)).keys.each do |method|
        # define_method :"#{method}=" do |value|
        #   set_value(method, value)
        # end
        # define_method :"#{method}" do
        #   get_value(method)
        # end
        # puts file_name
        # puts method.to_s
        puts "def #{method}\n  get_value('#{method}')\nend\n"
        puts "def #{method}=(value)\n  set_value('#{method}', value)\nend\n"
      end
      nil
    end

    def set_value(name, value)
      value = Float(value) rescue value
      redis.set name, value
      hash = YAML.load_file(file_name)
      hash[name]['value'] = value
      File.write(file_name, hash.to_yaml)
    end

    def get_value(name)
      value = redis.get(name)
      if value.nil?
        value = YAML::load_file(file_name)[name]['value']
        redis.set name, value
      end
      Float(value) rescue value
    end

    def cleanup
      self.version.to_i.downto 0 do |i|
        j = 0
        begin
          value = redis.get "#{i.to_f}_#{j}"
          redis.del "#{i.to_f}_#{j}"
          j += 1
        end until value.nil?
      end

      self.version = 0.0
    end

    def push
      keys.each do |key|
        redis.set "stack_#{key}", eval(key)
      end
    end

    def pop
      keys.each do |key|
        eval "self.#{key}= \"#{redis.get("stack_#{key}")}\""
      end
    end

    def local?
      RUBY_PLATFORM[/arm/].nil?
    end

    def rpi?
      !local?
    end

    def connected?
      File.exist? '/dev/cu.usbmodem3011' or File.exist? '/dev/cu.usbmodemInterface_3011' or File.exist? '/dev/serial/by-id/usb-Rozum_Robotics_USB-CAN_Interface_301-if00'
    end

  end
end
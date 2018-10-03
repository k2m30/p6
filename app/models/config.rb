class Config
  class << self
    %w(linear_velocity ff_velocity max_segment_length initial_x initial_y max_spray_length canvas_size_x canvas_size_y dm dy).each do |method|
      define_method :"#{method}=" do |value|
        Redis.new.set method, value
      end
      define_method :"#{method}" do
        value = Redis.new.get(method)
        if value.nil?
          value = YAML::load_file(Rails.root.join('config', 'config.yml'))[method]
          Redis.new.set method, value
        end
        value.to_f
      end
    end
  end
end
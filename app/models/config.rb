class Config
  class << self
    YAML.load(File.open(Rails.root.join('config','config.yml'))).keys.each do |method|
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
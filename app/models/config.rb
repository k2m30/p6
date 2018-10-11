class Config
  class << self
    file_name = Rails.root&.join('config','config.yml') || '/Users/user/projects/p6/config/config.yml'
    YAML.load(File.open(file_name)).keys.each do |method|
      define_method :"#{method}=" do |value|
        Redis.new.set method, value
      end
      define_method :"#{method}" do
        value = Redis.new.get(method)
        if value.nil?
          value = YAML::load_file(file_name)[method]
          Redis.new.set method, value
        end
        value.to_f
      end
    end
  end
end
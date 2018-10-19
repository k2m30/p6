class Config
  class << self
    file_name = Rails.root&.join('config', 'config.yml') || '/Users/user/projects/p6/config/config.yml'
    YAML.load(File.open(file_name)).keys.each do |method|
      define_method :"#{method}=" do |value|
        Redis.new.set method, value
        hash = YAML.load_file(file_name)
        hash[method]['value'] = value
        File.write(file_name, hash.to_yaml)
      end
      define_method :"#{method}" do
        value = Redis.new.get(method)
        if value.nil?
          value = YAML::load_file(file_name)[method]['value']
          Redis.new.set method, value
        end
        Float(value) rescue value
      end
    end
  end
end
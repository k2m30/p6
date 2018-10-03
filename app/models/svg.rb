require 'nokogiri'

class SVG
  attr_accessor :layers, :xml, :header, :name

  def initialize(file_name, path = Rails.root.join('public'))
    @redis = Redis.new
    @layers = {}
    @name = file_name
    @path = path
    @xml = Nokogiri::XML open(path + file_name)
    @xml.root.attributes['width'].value = '100%'
    @xml.root.attributes['height'].value = '100%'
    @header = @xml.root.attributes
    @redis.set(:header, @header)
    get_layer_names
  end

  def get_layer_names
    @xml.css('g').each do |e|
      if e.element? and e.name == 'g' and !e.attributes['id'].nil?
        @layers[e.attributes['id'].to_s] ||= nil
      end
    end
  end

  def get_layer(layer_name)
    @xml.css('g').each do |e|
      if e.element? and e.name == 'g' and !e.attributes['id'].nil?
        element_name = e.attributes['id'].to_s
        if layer_name == element_name
          @layers[layer_name] = Layer.new(e.to_s)
        end
      end
    end
    @layers[layer_name]
  end
end
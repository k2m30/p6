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
    @xml.traverse do |e|
      if e.element? and e.name == 'g' and !e.attributes['id'].nil?
        l = Layer.new(e)
        @layers[l.name] = l
      end
    end
  end
end
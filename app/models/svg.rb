require 'nokogiri'

class SVG
  attr_accessor :layers
  def initialize(file_name)
    @paths = []
    @layers = []
    elements = []
    svg = Nokogiri::XML open(file_name)
    svg.traverse do |e|
      if e.element?
        elements.push e
        @layers.push Layer.new(e) if e.name == 'g' and e.attributes['id'].present?
        # p [e.name, e.element?, e.try(:attributes)]
      end
    end
    elements.map do |e|
      @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    end
    # @paths.flatten!.map!(&:value).map! { |path| Path.parse path }.flatten!
  end
end
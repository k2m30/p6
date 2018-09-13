require 'nokogiri'
require 'tempfile'

class SVG
  attr_accessor :layers, :xml

  def initialize(file_name)
    @paths = []
    @layers = []
    @file_name = file_name
    elements = []
    svg = Nokogiri::XML open(file_name)
    svg.traverse do |e|
      if e.element?
        elements.push e
        @layers.push Layer.new(e) if e.name == 'g' and !e.attributes['id'].nil?
        if e.name == 'svg'
          p e.name
        end
      else
        next if e.name == 'text'
        # p e.name

      end
    end
    # elements.map do |e|
    #   @paths.push e.attribute_nodes.select { |a| a.name == 'd' }
    # end
    # @paths.flatten!.map!(&:value).map! { |path| Path.parse path }.flatten!
    @xml = svg
  end

  def build_svg(layer_name)
    layers = @layers.select { |l| l.name == layer_name }
    raise StandardError.new("More than one layer with the name #{layer_name}") if layer.size > 1
    raise StandardError.new("There is no layer with the name #{layer_name}") if layer.size == 0
    layer = layers.first

    header = @xml.root.attributes

    builder = Nokogiri::XML::Builder.new do |xml|
      #header and styles
      xml.doc.create_internal_subset(
          'svg',
          '-//W3C//DTD SVG 1.1//EN',
          'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'
      )
      xml.svg(version: '1.1',
              xmlns: 'http://www.w3.org/2000/svg',
              'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
              x: header['x'].to_s, y: header['y'].to_s,
              width: header['width'].to_s, height: header['height'].to_s,
              viewBox: header['viewBox'].to_s) {
        layer.paths.each do |path|
          xml.path(d: path.d, stroke: path.color, 'stroke-width': path.width)
        end

      }

    end

    file = Tempfile.new(layer_name)
    file.write builder.to_xml
    print "Saved to #{file.path}\n"
    file
  end
end
require 'nokogiri'
require 'tempfile'

class SVG
  attr_accessor :layers, :xml

  def initialize(path, file_name)
    @paths = []
    @layers = []
    @file_name = file_name
    @path = path
    @xml = Nokogiri::XML open(path + file_name)
    @xml.traverse do |e|
      @layers.push Layer.new(e) if e.element? and e.name == 'g' and !e.attributes['id'].nil?
    end
  end

  def build_svg(layer_name)
    layers = @layers.select { |l| l.name == layer_name }
    raise StandardError.new("More than one layer with the name #{layer_name}") if layers.size > 1
    raise StandardError.new("There is no layer with the name #{layer_name}") if layers.size == 0
    layer = layers.first
    layer.optimize_paths

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
              'xmlns:xlink': 'http://www.w3.org/1999/xlink',
              x: header['x'].to_s, y: header['y'].to_s,
              width: header['width'].to_s, height: header['height'].to_s,
              viewBox: header['viewBox'].to_s) do
        break if layer.paths.empty?
        last_point = layer.paths.first.start_point
        layer.paths.each_with_index do |path, i|
          xml.path(d: "M#{last_point.x},#{last_point.y} L#{path.start_point.x},#{path.start_point.y}", stroke: '#FF0000', 'stroke-width': (path.width/10).to_i, 'fill-opacity': 0, class: 'move_to')
          xml.path(d: path.d, stroke: path.color, 'stroke-width': path.width, 'fill-opacity': path.opacity, 'stroke-linecap': path.linecap, id: "path_#{i}")
          last_point = path.end_point
        end

      end
    end

    file = File.open(Rails.root.join('public', @file_name + '_' + layer_name + '.svg'), 'w')
    file.write builder.to_xml
    file.close
    File.basename file.path
  end
end
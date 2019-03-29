require 'csv'
require 'redis'
require 'json'

def do_it
  skip = %w[test.rb loop.rb graph.rb]
  Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
    require_relative f unless skip.any? {|s| s == f}
  end

  data = JSON.parse(Redis.new.get(:log))
  width = Config.canvas_size_x
  dm = Config.dm
  dy = Config.dy
  diameter = Config.motor_pulley_diameter
  points_str = ''


  data.each do |element|
    begin
      element.map!(&:to_f)
      left_belt = element[0] * Math::PI * diameter / 360.0
      right_belt = element[1] * Math::PI * diameter / 360.0
      point = Point.new(left_belt, right_belt).to_decart(width, dm, dy)
      points_str << "#{point.x},#{point.y} "
    rescue => e
      p e.message
    end
  end

  svg = <<SVG
<svg viewBox="0 0 #{Config.canvas_size_x.to_i} #{Config.canvas_size_y.to_i}" xmlns="http://www.w3.org/2000/svg">
  <polyline stroke="black" fill="none" points="#{points_str}" />
</svg>
SVG

  File.new('./result.svg', 'w').write(svg)
  puts svg
end

# do_it
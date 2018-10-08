require 'redis'
require 'rails'
require_relative 'svg'
require_relative 'layer'
require_relative 'path'
require_relative 'cubic_curve'
require_relative 'point'
require_relative 'move_to'
require_relative 'line'
require_relative 't_path'


x = 400.0
yy =[100.0, 150.0, 200.0, 250.0, 300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]

start_point = Point.new(400.0, 100.0)
end_point = Point.new(400.0, 600.0)
points = []
tpoints = []

width = 800.0
dm = 100.0
dy = 50.0
dl = 50.0

v = 100.0
a = 50.0

initial_point = Point.new(500.0, 500.0).to_decart(width, dm, dy)

yy.each do |y|
  point = Point.new(x, y)
  points << point
  tpoints << point.inverse(width, dm, dy)
end



move = MoveTo.new([initial_point, start_point])
line = Line.new([start_point, end_point])
path = Path.new([move, line])
spath = path.split(dl)

spath.elements.size.times do |i|
  p [i, spath.get_time(i, v, a)]
end
tpath = TPath.new(spath, width, dm, dy)
puts tpath

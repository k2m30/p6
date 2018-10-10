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

start_point = Point.new(400.0, 100.0)
end_point = Point.new(400.0, 600.0)

width = 800.0
dm = 100.0
dy = 50.0
dl = 50.0

pulley_diameter = 200.0
max_velocity = 100.0
a = 50.0

initial_point = Point.new(500.0, 500.0).to_decart(width, dm, dy)

move = MoveTo.new([initial_point, start_point])
line = Line.new([start_point, end_point])
path = Path.new([move, line])
spath = path.split(dl)


time_points = []
v_average_points = []
spath.elements.size.times do |i|
  time_points.push spath.get_time(i, max_velocity, a)
end
tpath = TPath.new(spath, width, dm, dy)
tpath.elements.each_cons(2) do |curr_e, next_e|
  i = tpath.elements.index(curr_e)
  j = tpath.elements.index(next_e)
  dt = time_points[j] - time_points[i]
  dp = next_e.end_point.x - curr_e.end_point.x
  v_average = dp / dt
  v_average_points << v_average
  p [curr_e, next_e, dp, dt, v_average]
end
puts tpath

velocity_points = [0]
v_average_points.each_cons(2) do |curr_v, next_v|
  velocity_points.push ((curr_v + next_v) / 2).round(2)
end
velocity_points.push 0

p v_average_points
p 'Results:'
p tpath.elements.map(&:end_point).map(&:x)
p velocity_points
p time_points
p [tpath.elements.map(&:end_point).map(&:x).size, velocity_points.size, time_points.size]

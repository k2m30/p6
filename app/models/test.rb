require 'redis'
require 'rack-mini-profiler'
require_relative 'svg'
require_relative 'layer'
require_relative 'path'
require_relative 'elements/cubic_curve'
require_relative 'elements/point'
require_relative 'elements/move_to'
require_relative 'elements/line'

l = Layer.from_redis 'yellow_('
t = Time.now
s = l.splitted_paths.last

s.elements.size.times {|i| [s.get_time(i, 200.0, 400.0)]}

p Time.now - t
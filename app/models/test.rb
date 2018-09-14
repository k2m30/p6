require_relative 'svg'
require_relative 'layer'
require_relative 'path'
require_relative 'elements/cubic_curve'
require_relative 'elements/point'
require_relative 'elements/move_to'
require_relative 'elements/line'

svg = SVG.new('../../public/','risovaka007_003.svg')
path = svg.layers[2].paths[2]
p path.d
path.reverse!
p path.d

file = svg.build_svg('black_up')
p file.path
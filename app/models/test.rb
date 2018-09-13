require_relative 'svg'
require_relative 'layer'
require_relative 'path'

svg = SVG.new('../assets/images/risovaka007_003.svg')
file = svg.build_svg('black_up')
p file.path
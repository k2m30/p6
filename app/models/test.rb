require 'redis'
require 'rails'
require 'csv'
require 'rack-mini-profiler'
require 'numo/gnuplot'


MIN_QUEUE_SIZE = 5
QUEUE_SIZE = 10
LEFT_MOTOR_ID = 19
RIGHT_MOTOR_ID = 32

def add_points(queue_size)
  queue_size.times do |i|
    path = @redis.get("#{Config.version}_#{@trajectory_index}")

    return if path.nil?

    path = JSON.parse path
    next_left_point = PVT.from_json path['left_motor_points'][@point_index]
    next_left_point.t *= 1000

    next_right_point = PVT.from_json path['right_motor_points'][@point_index]
    next_right_point.t *= 1000

    p [next_left_point, @trajectory_index, @point_index]
    @left_motor.add_point(next_left_point)
    @right_motor.add_point(next_right_point)

    if @point_index < path['left_motor_points'].size - 1
      @point_index += 1
    else
      @trajectory_index += 1
      @point_index = 1
    end

  rescue => e
    puts e.message
    puts e.backtrace

    @left_motor.velocity = 0.0
    fail 'Cannot send point'
  end
end


def initialize_motor(id)
  @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
  RRServoMotor.new(@servo_interface, id)
end

def do_it
  skip = %w[test.rb loop.rb graph.rb]
  Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
    require_relative f unless skip.any? {|s| s == f}
  end

  @redis = Redis.new

  @point_index = 1
  @trajectory_index = 0
  @zero_time = Time.now

  @left_motor = initialize_motor(LEFT_MOTOR_ID)
  @right_motor = initialize_motor(RIGHT_MOTOR_ID)

  @left_motor.clear_points_queue
  @right_motor.clear_points_queue

  left_point = 360.0 * Config.initial_x / (Math::PI * Config.motor_pulley_diameter)
  right_point = 360.0 * Config.initial_y / (Math::PI * Config.motor_pulley_diameter)
  @left_motor.go_to(pos: left_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)
  @right_motor.go_to(pos: right_point, max_velocity: Config.max_angular_velocity, acceleration: Config.max_angular_acceleration)

  @left_motor.add_motion_point(left_point, 0, 1000)
  @right_motor.add_motion_point(right_point, 0, 1000)

  @servo_interface.start_motion

  begin
    queue_size = @left_motor.queue_size
    if queue_size <= MIN_QUEUE_SIZE
      p queue_size
      add_points(QUEUE_SIZE)
    end
    @actual_points_left << @left_motor.position
    @actual_points_right << @right_motor.position
  end while queue_size > 0

end

def make_graph
  x = []
  y = []
  diameter = Config.motor_pulley_diameter
  width = Config.canvas_size_x
  dm = Config.dm
  dy = Config.dy
  canvas_size_y = Config.canvas_size_y

  @actual_points_left.size.times do |i|
    xx = @actual_points_left[i] * Math::PI * diameter / 360.0
    yy = @actual_points_right[i] * Math::PI * diameter / 360.0
    point = Point.new(xx, yy).to_decart(width, dm, dy)
    x << point.x
    y << canvas_size_y - point.y
  end


  file_name = './path.html'

  Numo.gnuplot do
    reset
    unset :multiplot
    # set title: "trajectory #{n}, left motor"
    set ylabel: ''
    set autoscale: :fix
    # set xlabel: 'time, s'

    set terminal: ['svg', 'size 1200,1200']
    set output: file_name
    set multiplot: 'layout 1,1'

    # figure
    set xrange: "[0:#{Config.canvas_size_x}]"
    set yrange: "[0:#{Config.canvas_size_y}]"
    set size: :square
    unset :xlabel

    plot x, y, w: 'lp' #, smooth: 'csplines'
  end
end

# @actual_points_left = []
# @actual_points_right = []

# do_it
# make_graph
#
#

# skip = %w[test.rb loop.rb graph.rb]
# Dir.glob('*.rb').map {|f| File.basename f}.each do |f|
#   require_relative f unless skip.any? {|s| s == f}
# end
#
# @motor = initialize_motor(RIGHT_MOTOR_ID)
# @motor.clear_points_queue
# t = @motor.go_to(pos: 1000, start_immediately: true)
# @motor.log_pvt(t + 1.0)
# `gnuplot ./plot.gnu`
#

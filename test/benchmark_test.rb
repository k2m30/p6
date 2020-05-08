require 'test_helper'
require "minitest/benchmark"

class TestLayerBuild < Minitest::Benchmark
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    Config.push
    Config.canvas_size_x = 6000.0
    Config.initial_x = 3500.0
    Config.initial_y = 3500.0
    Config.max_segment_length = 30.0
    Config.image_name = 'risovaka007_003.svg'

    @image = build_image
    layer_name = 'yellow_('
    @image.get_layer(layer_name)
    @proc = Proc.new do |max_segment_length|
      Config.max_segment_length = max_segment_length
      Layer.build(layer_name)
    end
  end

  def bench_build_20
    puts 'Segment length 1: ' <<
             Benchmark.ms {
               @proc.call(20.0)
             }.to_s <<
             ' ms'
  end

  def bench_build_10
    puts 'Segment length 10: ' <<
             Benchmark.ms {
               @proc.call(10.0)
             }.to_s <<
             ' ms'
  end

  def bench_build_30
    puts 'Segment length 30: ' <<
             Benchmark.ms {
               @proc.call(30.0)
             }.to_s <<
             ' ms'
  end

  def teardown
    Config.pop
  end
end
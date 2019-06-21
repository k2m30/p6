require 'test_helper'
require "minitest/benchmark"

class TestLayerBuild < Minitest::Benchmark
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    file_name = 'risovaka007_003.svg'
    layer_name = 'yellow_('
    @image = build_image file_name
    @image.get_layer(layer_name)
    @proc = Proc.new do |max_segment_length|
      Config.max_segment_length = max_segment_length
      Layer.build(layer_name)
    end
  end

  def bench_build_20
    Config.push
    puts 'Segment length 1: ' <<
             Benchmark.ms {
               @proc.call(20.0)
             }.to_s <<
             ' ms'
    Config.pop
  end

  def bench_build_10
    Config.push
    puts 'Segment length 10: ' <<
             Benchmark.ms {
               @proc.call(10.0)
             }.to_s <<
             ' ms'
    Config.pop
  end

  def bench_build_30
    Config.push
    puts 'Segment length 30: ' <<
             Benchmark.ms {
               @proc.call(30.0)
             }.to_s <<
             ' ms'
  end
  Config.pop
end
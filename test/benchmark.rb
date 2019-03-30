require "minitest/benchmark"

class TestLayerBuild < Minitest::Benchmark
  def setup
    puts '____________________________________________________________________________'
    Redis.new.flushall
    file_name = 'risovaka007_003.svg'
    name = 'yellow_('
    path = Rails.root.join('public')
    @image = SVG.new(file_name, path)
    @image.get_layer(name)
    @proc = Proc.new do |max_segment_length|
      old_segment_length = Config.max_segment_length
      Config.max_segment_length = max_segment_length
      Layer.build(name)
      Config.max_segment_length = old_segment_length
    end
  end

  def bench_build_1
    puts 'Segment length 1: ' <<
             Benchmark.ms {
               @proc.call(1.0)
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
end
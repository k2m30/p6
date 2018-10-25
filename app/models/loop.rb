require 'redis'

class Loop
  MIN_QUEUE_SIZE = 3.0 #sec
  QUEUE_SIZE = 10.0 #sec
  LEFT_MOTOR_ID = 0x20
  RIGHT_MOTOR_ID = 0x21

  def initialize
    @redis = Redis.new

    fail 'Already running' unless @redis.get('running').nil?

    @redis.set 'running', true
    @point_index = 0
    @trajectory_point_index = 0
    @last_sent_point = nil
    @left_motor = initialize_motor(LEFT_MOTOR_ID)
    @right_motor = initialize_motor(RIGHT_MOTOR_ID)
    @zero_time = Time.now # Process.clock_gettime(Process::CLOCK_MONOTONIC)
    run
  ensure
    @redis.del 'running'
  end

  def initialize_motor(id)
    @servo_interface ||= Servo.init_interface
    Servo.init_servo(id)
  end

  def run
    loop do
      if @redis.get('running').nil?
        soft_stop
        fail 'Stopped outside'
      end

      if check_queue_size <= MIN_QUEUE_SIZE
        return if add_points(QUEUE_SIZE) == 0
      end
      sleep 1.0
    end
  end

  def add_points(queue_size)
    begin
      path = JSON.parse(@redis.get("#{Config.version}_#{@point_index}"))

      if path.nil?
        puts 'All trajectories sent to motors, waiting for completion'
        begin
          sleep 1
        end while Time.now - (@zero_time + @last_sent_point['t']) < 0
        @redis.del 'running'
        puts 'Done'
        return 0
      end

      next_left_point = PVT.from_json path['left_motor_points'][@trajectory_point_index]
      next_right_point = PVT.from_json path['right_motor_points'][@trajectory_point_index]

      result_left = @left_motor.add_point(next_left_point)
      result_right = @right_motor.add_point(next_right_point)

      unless result_left.zero? and result_right.zero?
        soft_stop
        fail 'Cannot send point'
      end

      @last_sent_point = next_left_point

      if @trajectory_point_index <= path['size'] - 1
        @trajectory_point_index += 1
      else
        @trajectory_point_index = 0
        @point_index += 1
      end
    end until @last_sent_point['t'] - Time.now < queue_size


    def check_queue_size
      @last_sent_point.nil? ? 0.0 : @last_sent_point['t'] - (Time.now - @zero_time)
    end
  end

  def soft_stop
    turn_off_painting # it's better to check for the 'running' key inside the painting loop
    @left_motor.soft_stop
    @right_motor.soft_stop
  end
end
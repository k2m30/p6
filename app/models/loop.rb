require 'redis'

class Loop
  MIN_QUEUE_SIZE = 3.0 #sec
  QUEUE_SIZE = 10.0 #sec
  LEFT_MOTOR_ID = 19
  RIGHT_MOTOR_ID = 32

  NO_POINTS_IN_QUEUE_LEFT = 0

  def initialize
    @redis = Redis.new

    fail 'Already running' unless @redis.get('running').nil?

    @point_index = 0
    @trajectory_point_index = 0
    @last_sent_point = nil
    @left_motor = initialize_motor(LEFT_MOTOR_ID)
    @right_motor = initialize_motor(RIGHT_MOTOR_ID)
    @zero_time = Time.now # Process.clock_gettime(Process::CLOCK_MONOTONIC)
    run
  ensure
    turn_off_painting
    @redis.del 'running'
  end

  def initialize_motor(id)
    @servo_interface ||= RRInterface.new('/dev/cu.usbmodem301')
    RRServoMotor.new(@servo_interface, id)
  end

  def run
    loop{break unless @redis.get('running').nil? }

    loop do
      if @redis.get('running').nil?
        soft_stop
        fail 'Stopped outside'
      end

      if check_queue_size <= MIN_QUEUE_SIZE
        return if add_points(QUEUE_SIZE) == NO_POINTS_IN_QUEUE_LEFT
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

      begin
        @left_motor.add_point(next_left_point)
        @right_motor.add_point(next_right_point)
      rescue => e
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
  end

  def check_queue_size
    @last_sent_point.nil? ? 0.0 : @last_sent_point['t'] - (Time.now - @zero_time)
  end

  def soft_stop
    turn_off_painting # it's better to check for the 'running' key inside the painting loop
    @left_motor.soft_stop
    @right_motor.soft_stop
  end

  def turn_off_painting
    # code here
  end
end
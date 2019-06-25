class Row
  attr_accessor :end_left_deg,
                :end_right_deg,

                :start_left_deg,
                :start_right_deg,

                :v_left,
                :v_right,

                :dt,
                :t,

                :x,
                :y,

                :dl,
                :l,

                :left_mm,
                :right_mm,

                :linear_velocity,

                :v_average_left,
                :v_average_right,

                :a_left,
                :a_right

  def to_s
    "#{start_left_deg}, #{v_left}, #{a_left}, #{dt} | #{start_right_deg}, #{v_right}, #{a_right}, #{dt}"
  end

  def inspect
    to_s
  end

  def self.to_csv(data:, file_name: 'data.csv')
    CSV.open(file_name, 'wt') do |csv|
      csv << %w[left_deg right_deg, v_left, v_right, dt, t, x, y, dl, l, left_mm, right_mm, linear_velocity, v_average_left, v_average_right, a_left, a_right]
      data.each do |row|
        csv << row.to_csv
      end
    end
  end

end

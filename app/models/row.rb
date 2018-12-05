class Row
  attr_accessor :left_deg,
                :right_deg,

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
                :v_average_right

  def to_s
    "#{left_deg}, #{v_left}, #{dt} | #{right_deg}, #{v_right}, #{dt}"
  end

  def inspect
    to_s
  end
end

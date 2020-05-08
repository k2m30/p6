module ApplicationHelper
  def get_state
    state = JSON[Redis.new.get('state') || {left: 0.0, right: 0.0, x: 0, y: 0.0, running: false}.to_json, symbolize_names: true]
    point_belts = Point.new(state[:left], state[:right]).get_belts_length rescue Point.new(0.0, 0.0)
    point_decart = point_belts.to_decart rescue Point.new(0.0, 0.0)
    state.merge(left_mm: point_belts.x, right_mm: point_belts.y, x: point_decart.x, y: point_decart.y, current_trajectory: Config.start_from.to_i)
  end
end

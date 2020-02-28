ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"

MiniTest::Reporters.use!

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

# class ActiveSupport::TestCase
#   # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
#   # fixtures :all
#   # Add more helper methods to be used by all tests here...
# end

def build_image(file_name = Config.image_name)
  path = Rails.root.join("public")
  image = SVG.new(file_name, path)
  image.get_layer_names
  svg_x = image.header['width'].value.to_f
  fail "Wrong config, check config file or settings" if (svg_x > Config.canvas_size_x) or
      ((Config.initial_x + Config.initial_y) * 1.2 <= Config.canvas_size_x)
  image
end
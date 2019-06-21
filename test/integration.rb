require_relative 'test_helper'

class IntegrationTest < ActionDispatch::IntegrationTest
  test "can see the main page" do
    Redis.new.flushall
    Config.push
    image_name = 'risovaka007_003.svg'
    @image = build_image image_name
    layer_name = 'grey_('
    @image.get_layer(layer_name)
    Layer.build(layer_name)
    puts '____________________________________________________________________________'

    get "/"
    assert_response :success
    assert_select 'h5', image_name

    get "/?layer=#{layer_name}"
    assert_response :success
    assert_select '#image_name', image_name
    assert_select '#layer_name', layer_name

    get "/trajectory?id=46"
    assert_response :success

  ensure
    Config.pop
  end
end
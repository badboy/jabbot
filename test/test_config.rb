require 'helper'
require 'stringio'

context "Config" do
  test "default config is set" do
    config = Jabbot::Config.new
    assert_equal Jabbot::DEFAULT_CONFIG[:password], config.password
    assert_equal Jabbot::DEFAULT_CONFIG[:login], config.login
  end

  test "mirror missing methods as config setters" do
    config = Jabbot::Config.new
    assert_equal Jabbot::DEFAULT_CONFIG[:login], config.login

    val = "jabbot"
    config.login = val+'!'
    refute_equal Jabbot::DEFAULT_CONFIG[:login], config.login
    assert_equal val+'!', config.login
  end
end

require 'helper'
require 'stringio'

context "Config" do
  test "default configuration be a hash" do
    assert_not_nil Jabbot::Config::DEFAULT
    assert Jabbot::Config::DEFAULT.is_a?(Hash)
  end

  test "initialize with no options" do
    assert_hashes_equal({}, Jabbot::Config.new.settings)
  end

  test "return config from add" do
    config = Jabbot::Config.new
    assert_equal config, config.add(Jabbot::Config.new)
  end

  test "alias add to <<" do
    config = Jabbot::Config.new
    assert config.respond_to?(:<<)
    assert config << Jabbot::Config.new
  end

  test "mirror method_missing as config getters" do
    config = Jabbot::Config.default << Jabbot::Config.new
    assert_equal Jabbot::Config::DEFAULT[:password], config.password
    assert_equal Jabbot::Config::DEFAULT[:login], config.login
  end

  test "mirror missing methods as config setters" do
    config = Jabbot::Config.default << Jabbot::Config.new
    assert_equal Jabbot::Config::DEFAULT[:login], config.login

    val = "jabbot"
    config.login = val+'!'
    assert_not_equal Jabbot::Config::DEFAULT[:login], config.login
    assert_equal val+'!', config.login
  end

  test "not override default hash" do
    config = Jabbot::Config.default
    hash = Jabbot::Config::DEFAULT

    config.login = "jabbot"
    config.password = "secret"

    assert_hashes_not_equal Jabbot::Config::DEFAULT, config.to_hash
    assert_hashes_equal hash, Jabbot::Config::DEFAULT
  end

  test "return merged configuration from to_hash" do
    config = Jabbot::Config.new
    config.login = "jabbot"
    config.password = "secret"

    config2 = Jabbot::Config.new({})
    config2.login = "not_jabbot2"
    config << config2
    options = config.to_hash

    assert_equal "secret", options[:password]
    assert_equal "not_jabbot2", options[:login]
  end
end

context "FileConfig" do
  test "subclass config for file config" do
    assert Jabbot::FileConfig.new(StringIO.new).is_a?(Jabbot::Config)
  end

  test "read settings from stream" do
    config = Jabbot::FileConfig.new(StringIO.new <<-YAML)
  login: jabbot
  password: secret
      YAML

    assert_equal "jabbot", config.login
    assert_equal "secret", config.password
  end
end

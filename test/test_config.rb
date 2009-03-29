require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Jabbot)
require 'stringio'

class TestConfig < Test::Unit::TestCase
  should "default configuration be a hash" do
    assert_not_nil Jabbot::Config::DEFAULT
    assert Jabbot::Config::DEFAULT.is_a?(Hash)
  end

  should "initialize with no options" do
    assert_hashes_equal({}, Jabbot::Config.new.settings)
  end

  should "return config from add" do
    config = Jabbot::Config.new
    assert_equal config, config.add(Jabbot::Config.new)
  end

  should "alias add to <<" do
    config = Jabbot::Config.new
    assert config.respond_to?(:<<)
    assert config << Jabbot::Config.new
  end

  should "mirror method_missing as config getters" do
    config = Jabbot::Config.default << Jabbot::Config.new
    assert_equal Jabbot::Config::DEFAULT[:password], config.password
    assert_equal Jabbot::Config::DEFAULT[:login], config.login
  end

  should "mirror missing methods as config setters" do
    config = Jabbot::Config.default << Jabbot::Config.new
    assert_equal Jabbot::Config::DEFAULT[:login], config.login

    val = "jabbot"
    config.login = val+'!' 
    assert_not_equal Jabbot::Config::DEFAULT[:login], config.login
    assert_equal val+'!', config.login
  end

  should "not override default hash" do
    config = Jabbot::Config.default
    hash = Jabbot::Config::DEFAULT

    config.login = "jabbot"
    config.password = "secret"

    assert_hashes_not_equal Jabbot::Config::DEFAULT, config.to_hash
    assert_hashes_equal hash, Jabbot::Config::DEFAULT
  end

  should "return merged configuration from to_hash" do
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

class TestFileConfig < Test::Unit::TestCase
  should "subclass config for file config" do
    assert Jabbot::FileConfig.new(StringIO.new).is_a?(Jabbot::Config)
  end

  should "read settings from stream" do
    config = Jabbot::FileConfig.new(StringIO.new <<-YAML)
login: jabbot
password: secret
    YAML

    assert_equal "jabbot", config.login
    assert_equal "secret", config.password
  end
end

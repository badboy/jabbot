require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Jabbot)
require 'fileutils'

class TestBot < Test::Unit::TestCase
  should "not raise errors when initialized" do
    assert_nothing_raised do
      Jabbot::Bot.new Jabbot::Config.new
    end
  end

  should "raise errors when initialized without config file" do
    assert_raise SystemExit do
      Jabbot::Bot.new
    end
  end

  should "not raise error on initialize when config file exists" do
    if File.exists?("config")
      FileUtils.rm("config/bot.yml")
    else
      FileUtils.mkdir("config")
    end

    File.open("config/bot.yml", "w") { |f| f.puts "" }

    assert_nothing_raised do
      Jabbot::Bot.new
    end

    FileUtils.rm_rf("config")
  end

  should "provide configuration settings as methods" do
    bot = Jabbot::Bot.new Jabbot::Config.new(:login => "jabbot")
    assert_equal "jabbot", bot.login
  end

  should "return logger instance" do
    bot = Jabbot::Bot.new(Jabbot::Config.default << Jabbot::Config.new)
    assert bot.log.is_a?(Logger)
  end

  should "respect configured log level" do
    bot = Jabbot::Bot.new(Jabbot::Config.new(:log_level => "info"))
    assert_equal Logger::INFO, bot.log.level

    bot = Jabbot::Bot.new(Jabbot::Config.new(:log_level => "warn"))
    assert_equal Logger::WARN, bot.log.level
  end
end

class TestBotMacros < Test::Unit::TestCase
  should "provide configure macro" do
    assert respond_to?(:configure)
  end

  should "yield configuration" do
    Jabbot::Macros.bot = Jabbot::Bot.new Jabbot::Config.default

    conf = nil
    assert_nothing_raised { configure { |c| conf = c } }
    assert conf.is_a?(Jabbot::Config)
  end

   should "add handler" do
     Jabbot::Macros.bot = Jabbot::Bot.new Jabbot::Config.default

     handler = add_handler(:message, ":command", :from => :cjno)
     assert handler.is_a?(Jabbot::Handler), handler.class
   end

  should "provide client macro" do
    assert respond_to?(:client)
  end

  should "provide user macro" do
    assert respond_to?(:user)
  end
end

class TestBotHandlers < Test::Unit::TestCase

  should "include handlers" do
    bot = Jabbot::Bot.new(Jabbot::Config.new)

    assert_not_nil bot.handlers
    assert_not_nil bot.handlers[:message]
    assert_not_nil bot.handlers[:private]
    assert_not_nil bot.handlers[:join]
    assert_not_nil bot.handlers[:leave]
    assert_not_nil bot.handlers[:subject]
  end

  should "add handler" do
    bot = Jabbot::Bot.new(Jabbot::Config.new)
    bot.add_handler :message, Jabbot::Handler.new
    assert_equal 1, bot.handlers[:message].length

    bot.add_handler :message, Jabbot::Handler.new
    assert_equal 2, bot.handlers[:message].length

    bot.add_handler :private, Jabbot::Handler.new
    assert_equal 1, bot.handlers[:private].length

    bot.add_handler :private, Jabbot::Handler.new
    assert_equal 2, bot.handlers[:private].length

    bot.add_handler :join, Jabbot::Handler.new
    assert_equal 1, bot.handlers[:join].length

    bot.add_handler :join, Jabbot::Handler.new
    assert_equal 2, bot.handlers[:join].length

    bot.add_handler :leave, Jabbot::Handler.new
    assert_equal 1, bot.handlers[:leave].length

    bot.add_handler :leave, Jabbot::Handler.new
    assert_equal 2, bot.handlers[:leave].length

    bot.add_handler :subject, Jabbot::Handler.new
    assert_equal 1, bot.handlers[:subject].length

    bot.add_handler :subject, Jabbot::Handler.new
    assert_equal 2, bot.handlers[:subject].length
  end
end

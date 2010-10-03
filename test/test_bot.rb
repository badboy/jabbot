require 'helper'
require 'fileutils'

context "Bot" do
  test "raise no exceptions when initialized" do
    assert_nothing_raised do
      Jabbot::Bot.new Jabbot::Config.new
    end
  end

  test "raise exception when initialized without config file" do
    assert_raise SystemExit do
      Jabbot::Bot.new
    end
  end

  test "raise no exception on initialize when config file exists" do
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

  test "provide configuration settings as methods" do
    bot = Jabbot::Bot.new Jabbot::Config.new(:login => "jabbot")
    assert_equal "jabbot", bot.login
  end

  test "return logger instance" do
    bot = Jabbot::Bot.new(Jabbot::Config.default << Jabbot::Config.new)
    assert bot.log.is_a?(Logger)
  end

  test "respect configured log level" do
    bot = Jabbot::Bot.new(Jabbot::Config.new(:log_level => "info"))
    assert_equal Logger::INFO, bot.log.level

    bot = Jabbot::Bot.new(Jabbot::Config.new(:log_level => "warn"))
    assert_equal Logger::WARN, bot.log.level
  end
end

context "Handler DSL" do
  test "include handlers" do
    bot = Jabbot::Bot.new(Jabbot::Config.new)

    assert_not_nil bot.handlers
    assert_not_nil bot.handlers[:message]
    assert_not_nil bot.handlers[:private]
    assert_not_nil bot.handlers[:join]
    assert_not_nil bot.handlers[:leave]
    assert_not_nil bot.handlers[:subject]
  end

  test "add handler" do
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

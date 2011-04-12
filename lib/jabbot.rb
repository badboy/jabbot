require 'time'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
#require 'xmpp4r/muc/helper/mucclient'
require 'xmpp4r/version/helper/simpleresponder'
require 'yaml'
require File.join(File.dirname(__FILE__), 'hash')

require 'jabbot/bot.rb'
require 'jabbot/config.rb'
require 'jabbot/handlers.rb'
require 'jabbot/macros.rb'

module Jabbot
  VERSION = '0.3.0'

  @@app_file = lambda do
    ignore = [
      /lib\/twibot.*\.rb/, # Library
      /\(.*\)/,            # Generated code
      /custom_require\.rb/ # RubyGems require
    ]

    path = caller.map { |line| line.split(/:\d/, 2).first }.find do |file|
      next if ignore.any? { |pattern| file =~ pattern }
      file
    end

    path || $0
  end.call

  #
  # File name of the application file. Inspired by Sinatra
  #
  def self.app_file
    @@app_file
  end

  #
  # Runs application if application file is the script being executed
  #
  def self.run?
    self.app_file == $0
  end

end  # module Jabbot

Thread.abort_on_exception = true

# EOF

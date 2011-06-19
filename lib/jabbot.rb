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
  VERSION = '0.3.2-dev'

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

  # Public: File name of the application file (inspired by Sinatra).
  #
  # Returns the String application filename.
  def self.app_file
    @@app_file
  end

  # Public: Determines if the application should be auto-run.
  #
  # Returns a Boolean indicatin wether to auto-run the application or not.
  def self.run?
    self.app_file == $0
  end

end

# xmpp4r runs in another thread.
Thread.abort_on_exception = true

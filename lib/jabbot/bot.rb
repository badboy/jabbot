require 'logger'
require File.join(File.expand_path(File.dirname(__FILE__)), 'macros')
require File.join(File.expand_path(File.dirname(__FILE__)), 'handlers')

require 'eventmachine'

module Jabbot
  # A message consists of the username, the text, a time when it was received
  # and the type of the message.
  #
  # The type could be one Symbol of:
  #
  #   * :public
  #   * :query
  #   * :join
  #   * :leave
  #   * :subject
  #
  Message = Struct.new(:user, :text, :time, :type) do
    # Public: Converts the message to printable text.
    #
    # Returns a String containing the user's name and the text.
    def to_s
      "#{user}: #{text}"
    end

    # Public: Encode a message in JSON
    #
    # Returns the json-ified String of the Hash representation of this message.
    def to_json(*a)
      {
        :user => user,
        :text => text,
        :time => time,
        :type => type
      }.to_json(*a)
    end
  end

  # The main Bot class.
  #
  # It handles the connection as well as the method dispatching.
  class Bot
    include Jabbot::Handlers
    attr_reader :client
    attr_reader :users


    # Public: Initialize a Bot instance.
    #
    # options - A Jabbot::Config options instance or a Hash of key-value
    #           configuration options (default: {}).
    def initialize(options={})
      @config = if options.kind_of?(Jabbot::Config)
        options
      else
        Jabbot::Config.new(options)
      end
      @log = nil
      @abort = false
      @users = []

    rescue Exception => krash
      raise SystemExit.new(krash.message)
    end

    # Internal: Enable debugging mode.
    #
    # All xmpp4r-internal calls to Jabber::Debuglog are
    # printed to $stderr by default.
    # You may change the logger by using
    #
    #   Jabber::Logger = Logger.new(…)
    #
    # Returns nothing.
    def debug!
      Jabber::debug = true
    end

    # Internal: Connect to Jabber and join channel.
    #
    # It will exit the process and log any exception
    # on `$stderr` on failure.
    #
    # Returns nothing.
    def connect
      @jid = Jabber::JID.new(config.login)
      @mucjid = Jabber::JID.new("#{config.channel}@#{config.server}")

      if @jid.node.nil?
        raise "Your Jabber ID must contain a user name and therefore contain one @ character."
      elsif @jid.resource
        raise "If you intend to set a custom resource, define so in the config."
      elsif @mucjid.node.nil?
        raise "Please set a room name, e.g. myroom@conference.jabber.org"
      elsif @mucjid.resource
        raise "The MUC room must not contain a resource. Remove the slash!"
      else
        @jid.resource = config.resource
        @mucjid.resource = config.nick
        @users << config.nick
      end

      @client = Jabber::Client.new(@jid)
      @client.on_exception do |*args|
        $stderr.puts "got an intern EXCEPTION, args where:"
        $stderr.puts args.inspect
        $stderr.puts "exiting..."

        EventMachine.stop_event_loop
        exit
      end
      begin
        @client.connect
        @client.auth(config.password)
        @muc = Jabber::MUC::SimpleMUCClient.new(@client)
        muc_handlers.call(@muc)
        @muc.join(@mucjid)
        @connected = true
      rescue => errmsg
        @connected = false
        $stderr.write "#{errmsg.class}\n#{errmsg}, #{errmsg.backtrace.join("\n")}"
        exit 1
      end
    end

    # Public: Starts the jabber bot.
    #
    # Internally it starts the jabber connection inside of `EventMachine.run`,
    # so you are free to use all EventMachine tasks out there for asynchronously
    # working on input data.
    #
    # Returns nothing.
    def run!
      puts "Jabbot #{Jabbot::VERSION} imposing as #{config.login} on #{config.channel}@#{config.server}"

      onclose_block = proc {
        close
        puts "\nAnd it's a wrap. See ya soon!"
        exit
      }

      Kernel.trap(:INT, onclose_block)
      Kernel.trap(:QUIT, onclose_block) rescue nil

      debug! if config.debug

      # Connect the bot and keep it running.
      EventMachine.run do
        connect

        stop_timer = EventMachine.add_periodic_timer(1) do
          if !connected?
            EventMachine.stop_event_loop
          end
        end
      end
    end

    # Internal: Get information if the bot is still connected.
    #
    # Returns the connection state as a Boolean.
    def connected?
      @connected
    end

    # Public: Close the server connection.
    #
    # Returns nothing.
    def close
      if connected?
        @connected = false
        client.close
      end
    end
    alias_method :quit, :close

    # Public: Send a message to a given user or publicly.
    #
    # msg - A String message.
    # to  - A String username to send to (default: nil).
    #
    # Returns nothing.
    def send_message(msg, to=nil)
      @muc.say(msg.to_s, to) if connected?
    end

    # Internal: Assigns handlers for different xmpp messages.
    #
    # The handled messages are:
    #
    #   * public messages
    #   * private messages
    #   * joins
    #   * leaves
    #   * subject changes
    #
    # Returs a Proc to be called to assign the handlers.
    def muc_handlers
      Proc.new do |muc|
        muc.on_message do |time, nick, text|
          if time.nil? # Don't process messages from the past.
            begin
              dispatch_messages(:message, [Message.new(nick, text, Time.now, :public)]) unless nick == config.nick
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_private_message do |time, nick, text|
          if time.nil? # Don't process messages from the past.
            begin
              dispatch_messages(:private, [Message.new(nick, text, Time.now, :private)]) unless nick == config.nick
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_join do |time, nick|
          unless @users.include? nick
            @users << nick
          end
          if time.nil? # Don't process messages from the past.
            begin
              dispatch_messages(:join, [Message.new(nick, "join", Time.now, :join)]) unless nick == config.nick
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_leave do |time, nick|
          @users.delete(nick)
          if time.nil? # Don't process messages from the past.
            begin
              dispatch_messages(:leave, [Message.new(nick, "leave", Time.now, :leave)])
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_subject do |time, nick, subject|
          if time.nil? # Don't process messages from the past.
            begin
              dispatch_messages(:subject, [Message.new(nick, subject, Time.now, :subject)])
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end
      end
    end

    # Internal: Dispatch a collection of messages.
    #
    # type     - The Symbol type to be processed.
    # messages - An Array of String messages to be dispatched.
    #
    # Returns the Integer count of messages dispatched.
    def dispatch_messages(type, messages)
      messages.each { |message| dispatch(type, message) }
      messages.length
    end

    # Internal: Instanciates a logger.
    #
    # Returns logger instance.
    def log
      return @log if @log
      os = config.log_file ? File.open(config.log_file, "a") : $stdout
      @log = Logger.new(os)
      @log.level = Logger.const_get(config.log_level ? config.log_level.upcase : "INFO")
      @log
    end

    # Public: Set configure options for the bot.
    #
    # Returns the configure Hash.
    def configure
      yield @config
    end

    # Public: Get the current configuration settings.
    #
    # Returns the configuration Hash.
    def config
      @config
    end

    # Public: Easy access to the bot's nickname
    #
    # Returns the configured nick String.
    def nick
      @config.nick
    end
  end
end

# Expose DSL
include Jabbot::Macros

# Run bot if macros has been used.
at_exit do
  raise $! if $!
  @@bot.run! if run?
end

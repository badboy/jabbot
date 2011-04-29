require 'logger'
require File.join(File.expand_path(File.dirname(__FILE__)), 'macros')
require File.join(File.expand_path(File.dirname(__FILE__)), 'handlers')

module Jabbot
  #
  # Main bot "controller" class
  #
  class Bot
    include Jabbot::Handlers
    attr_reader :client
    attr_reader :users

    Message = Struct.new(:user, :text, :time, :type) do
      def to_s
        "#{user}: #{text}"
      end
    end

    def initialize(options = nil)
      @conf = nil
      @config = options || Jabbot::Config.default << Jabbot::FileConfig.new
      @log = nil
      @abort = false
      @users = []

    rescue Exception => krash
      raise SystemExit.new(krash.message)
    end

    # Enable debugging mode.
    # All xmpp4r-internal calls to Jabber::Debuglog are
    # printed to $stderr by default.
    # You may change the logger by using
    #   Jabber::Logger = Logger.new(…)
    def debug!
      Jabber::debug = true
    end

    #
    # connect to Jabber and join channel
    #
    def connect
      @jid = Jabber::JID.new(login)
      @mucjid = Jabber::JID.new("#{channel}@#{server}")

      if @jid.node.nil?
        raise "Your Jabber ID must contain a user name and therefore contain one @ character."
      elsif @jid.resource
        raise "If you intend to set a custom resource, put that in the right text field. Remove the slash!"
      elsif @mucjid.node.nil?
        raise "Please set a room name, e.g. myroom@conference.jabber.org"
      elsif @mucjid.resource
        raise "The MUC room must not contain a resource. Remove the slash!"
      else
        @jid.resource = config[:resource] || "jabbot"
        @mucjid.resource = config[:nick] || "jabbot"
        @users << config[:nick]
      end

      @client = Jabber::Client.new(@jid)
      @client.on_exception do |*args|
        $stderr.puts "got an intern EXCEPTION, args where:"
        $stderr.puts args.inspect
        $stderr.puts "exiting..."

        exit
      end
      @connected = true
      begin
        @client.connect
        @client.auth(password)
        @muc = Jabber::MUC::SimpleMUCClient.new(@client)
        muc_handlers.call(@muc)
        @muc.join(@mucjid)
       rescue => errmsg
        $stderr.write "#{errmsg.class}\n#{errmsg}, #{errmsg.backtrace.join("\n")}"
        exit 1
      end
    end

    #
    # Run application
    #
    def run!
      puts "Jabbot #{Jabbot::VERSION} imposing as #{login} on #{channel}@#{server}"

      onclose_block = proc {
        close
        puts "\nAnd it's a wrap. See ya soon!"
        exit
      }

      Kernel.trap(:INT, onclose_block)
      Kernel.trap(:QUIT, onclose_block)

      debug! if config[:debug]
      connect
      poll
    end

    #
    # just a lame infinite loop to keep the bot alive while he is connected
    # :)
    #
    def poll
      while connected?
        break unless connected?
        sleep 1
      end
    end

    #
    # still connected?
    #
    def connected?
      @connected
    end

    #
    # close connection
    #
    def close
      if connected?
        @connected = false
        client.close
      end
    end
    alias_method :quit, :close

    #
    # send message
    # alternative: send query to user
    #
    def send_message(msg, to=nil)
      @muc.say(msg.to_s, to)
    end

    #
    # defines what to do on different actions
    #
    def muc_handlers
      Proc.new do |muc|
        muc.on_message do |time, nick, text|
          if time.nil?
            begin
              dispatch_messages(:message, [Message.new(nick, text, Time.now, :public)]) unless nick == config[:nick]
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_private_message do |time, nick, text|
          if time.nil?
            begin
              dispatch_messages(:private, [Message.new(nick, text, Time.now, :query)]) unless nick == config[:nick]
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
          if time.nil?
            begin
              dispatch_messages(:join, [Message.new(nick, "join", Time.now, :join)]) unless nick == config[:nick]
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_leave do |time, nick|
          @users.delete(nick)
          if time.nil?
            begin
              dispatch_messages(:leave, [Message.new(nick, "leave", Time.now, :leave)])
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        muc.on_subject do |time, nick, subject|
          if time.nil?
            begin
              dispatch_messages(:subject, [Message.new(nick, subject, Time.now, :subject)])
            rescue Exception => boom
              log.fatal boom.inspect
              log.fatal boom.backtrace[0..5].join("\n")
            end
          end
        end

        # not working
        #muc.on_self_leave  do |*args|
        #  p args
        #end
      end
    end

    #
    # Dispatch a collection of messages
    #
    def dispatch_messages(type, messages)
      messages.each { |message| dispatch(type, message) }
      messages.length
    end

    #
    # Return logger instance
    #
    def log
      return @log if @log
      os = config[:log_file] ? File.open(config[:log_file], "a") : $stdout
      @log = Logger.new(os)
      @log.level = Logger.const_get(config[:log_level] ? config[:log_level].upcase : "INFO")
      @log
    end

    #
    # Configure bot
    #
    def configure
      yield @config
      @conf = nil
    end

    #
    # Map configuration settings
    #
    def method_missing(name, *args, &block)
      return super unless config.key?(name)

      self.class.send(:define_method, name) { config[name] }
      config[name]
    end

    #
    # Return configuration
    #
    def config
      return @conf if @conf
      @conf = @config.to_hash
    end
  end
end

# Expose DSL
include Jabbot::Macros

# Run bot if macros has been used
at_exit do
  raise $! if $!
  @@bot.run! if run?
end

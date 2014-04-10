module Jabbot
  # Default configuration values.
  # If an option is not set on creation,
  # it gets the default value instead.
  DEFAULT_CONFIG = {
    :login     => nil,
    :password  => nil,
    :nick      => 'jabbot',
    :server    => nil,
    :channel   => nil,
    :channelpw => nil,
    :resource  => 'jabbot',
    :log_level => 'info',
    :log_file  => nil,
    :debug     => false
  }

  # The main configuration of Jabbot.
  # It's nothing more than a simple struct of key-value pairs.
  #
  # Examples:
  #
  #   Jabbot::Config.new({:login => "jabbot@server.com", :password => "secret",
  #                       :debug => true})
  #   # => #<struct Jabbot::Config login="jabbot@server.com", password="secret",
  #        nick="jabbot", server=nil, channel=nil, resource="jabbot",
  #        log_level="info", log_file=nil, debug=true>
  #
  #   Jabbot::Config.new("jabbot@server.com", "secret")
  #   # => #<struct Jabbot::Config login="jabbot@server.com", password="secret",
  #        nick="jabbot", server=nil, channel=nil, resource="jabbot",
  #        log_level="info", log_file=nil, debug=false>
  #
  #   config.login
  #   # => "jabbot@server.com"
  #   config.channel
  #   # => nil
  #   config.channel = "room@conference.server.com"
  #   # => "room@conference.server.com"
  #
  Config = Struct.new(
    # We need the correct order here, so this is done manually.
    :login,
    :password,
    :nick,
    :server,
    :channel,
    :channelpw, 
    :resource,
    :log_level,
    :log_file,
    :debug
  ) do
    # Public: Initialize new configuration object.
    #
    # *args - Any number of valid arguments passed to the super class.
    #         If there is only one argument and it is kind of a Hash,
    #         it is treated as the key-value pairs are the options.
    #         If there is a default value for an option key,
    #         it is set if needed.
    def initialize(*args)
      # First: call the super class.
      super

      # If we got a hash, treat it as the configuration options.
      if args.size == 1 && args.first.kind_of?(Hash)
        self.login = nil # Reset first value.

        args.first.each do |key, value|
          send("#{key}=", value)
        end
      end

      # Set defaults.
      DEFAULT_CONFIG.each do |key, value|
        self.send(key.to_s) || self.send("#{key}=", value)
      end
    end
  end
end

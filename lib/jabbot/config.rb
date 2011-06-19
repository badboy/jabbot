require 'optparse'

module Jabbot
  # Jabbot configuration. Use either Jabbot::CliConfig.new or
  # JabbotFileConfig.new setup a new bot from either command line or file
  # (respectively). Configurations can be chained so they override each other:
  #
  #   config = Jabbot::FileConfig.new
  #   config << Jabbot::CliConfig.new
  #   config.to_hash
  #
  # The preceding example will create a configuration which is based on a
  # configuration file but have certain values overridden from the command line.
  # This can be used for instance to store everything but the Twitter account
  # password in your configuration file. Then you can just provide the password
  # when running the bot.
  #
  class Config
    attr_reader :settings

    DEFAULT = {
      :log_level => 'info',
      :log_file => nil,
      :login => nil,
      :password => nil,
      :nick => 'jabbot',
      :channel => nil,
      :server => nil,
      :resource => nil,
      :debug => false
    }

    def initialize(settings = {})
      @configs = []
      @settings = settings
    end

    # Public: Add a configuration object to override given settings
    #
    # config -
    #
    # Returns the class object.
    def add(config)
      @configs << config
      self
    end
    alias_method :<<, :add

    # Internal: Maps calls to non existant functions to
    #           configuration values, if they exist.
    #
    # name, *args and &block as described in the core classes.
    #
    # Returns the configuration value if any.
    def method_missing(name, *args, &block)
      regex = /=$/
      attr_name = name.to_s.sub(regex, '').to_sym
      return super if name == attr_name && !@settings.key?(attr_name)

      if name != attr_name
        @settings[attr_name] = args.first
      end

      @settings[attr_name]
    end

    # Public: Merges configurations and returns a hash with all options
    #
    # Returns a Hash of the configuration.
    def to_hash
      hash = {}.merge(@settings)
      @configs.each { |conf| hash.merge!(conf.to_hash) }
      hash
    end

    def self.default
      Config.new({}.merge(DEFAULT))
    end
  end

  # Deprecated: Configuration from files
  class FileConfig < Config
    # Public: Initializes a new FileConfig object.
    #
    #
    # fos - Accepts a Stream or a String filename to read configuration from
    #       (default: "./config/bot.yml")
    #       If a stream is passed it is not closed from within the method.
    def initialize(fos = File.expand_path("config/bot.yml"))
      warn "Jabbot::FileConfig is deprecated and will be removed in the next version."

      stream = fos.is_a?(String) ? File.open(fos, "r") : fos

      begin
        config = YAML.load(stream.read)
        config.symbolize_keys! if config
      rescue Exception => err
        puts err.message
        puts "Unable to load configuration, aborting"
        exit
      ensure
        stream.close if fos.is_a?(String)
      end

      super config.is_a?(Hash) ? config : {}
    end
  end
end

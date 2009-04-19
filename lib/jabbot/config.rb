require 'optparse'

module Jabbot
  #
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
      :resource => nil
    }

    def initialize(settings = {})
      @configs = []
      @settings = settings
    end

    #
    # Add a configuration object to override given settings
    #
    def add(config)
      @configs << config
      self
    end

    alias_method :<<, :add

    #
    # Makes it possible to access configuration settings as attributes
    #
    def method_missing(name, *args, &block)
      regex = /=$/
      attr_name = name.to_s.sub(regex, '').to_sym
      return super if name == attr_name && !@settings.key?(attr_name)

      if name != attr_name
        @settings[attr_name] = args.first
      end

      @settings[attr_name]
    end

    #
    # Merges configurations and returns a hash with all options
    #
    def to_hash
      hash = {}.merge(@settings)
      @configs.each { |conf| hash.merge!(conf.to_hash) }
      hash
    end

    def self.default
      Config.new({}.merge(DEFAULT))
    end
  end

  #
  # Configuration from files
  #
  class FileConfig < Config

    #
    # Accepts a stream or a file to read configuration from
    # Default is to read configuration from ./config/bot.yml
    #
    # If a stream is passed it is not closed from within the method
    #
    def initialize(fos = File.expand_path("config/bot.yml"))
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

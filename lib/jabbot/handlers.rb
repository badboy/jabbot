module Jabbot
  module Handlers
    #
    # Add a handler for this bot
    #
    def add_handler(type, handler)
      handlers[type] << handler
      handler
    end

    def dispatch(type, message)
      handlers[type].each {|handler| handler.dispatch(message) }
    end

    def handlers
      @handlers ||= {
        :message => [],
        :private => [],
        :join => [],
        :subject => [],
        :leave => []
      }
    end

    def handlers=(hash)
      @handlers = hash
    end
  end

  #
  # A Handler object is an object which can handle any type of message
  #
  class Handler
    def initialize(pattern = nil, options = {}, &blk)
      @exact_match = false
      if pattern.is_a?(Hash)
        if pattern.keys.first == :exact
          @exact_match = true
          pattern = pattern[:exact]
        else
          options = pattern
          pattern = nil
        end
      end

      @options = options
      if from = @options[:from]
        if from.respond_to?(:collect)
          @options[:from] = from.collect {|s| s.to_s }
        elsif from.respond_to?(:to_s)
          @options[:from] = [@options[:from].to_s]
        else
          @options[:from] = nil
        end
      end

      @handler = block_given? ? blk : nil

      # Set pattern (parse it if needed)
      self.pattern = pattern
    end

    #
    # Parse pattern string and set options
    #
    def pattern=(pattern)
      @pattern = nil
      return if pattern.nil? || pattern == '' || pattern == :all

      if pattern.is_a?(Regexp)
        @options[:pattern] = pattern
        @pattern = pattern
        return
      end

      words = pattern.split.collect {|s| s.strip }   # Get all words in pattern
      @tokens = words.inject([]) do |sum, token|     # Find all tokens, ie :symbol :like :names
        next sum unless token =~ /^:.+/              # Don't process regular words
        sym = token.sub(':', '').to_sym              # Turn token string into symbol, ie ":token" => :token
        regex = @options[sym] || '[^\s]+'            # Fetch regex if configured, else use any character but space matching
        pattern.sub!(/(^|\s)#{token}(\s|$)/, '\1(' + regex.to_s + ')\2') # Make sure regex captures named switch
        sum << sym
      end

      if @exact_match
        @pattern = /\A#{pattern}\Z/
      else
        @pattern = /#{pattern}/
      end
    end

    #
    # Determines if this handler is suited to handle an incoming message
    #
    def recognize?(message)
      return false if @pattern && message.text !~ @pattern

      users = @options[:from] ? @options[:from] : nil
      return false if users && !users.include?(message.user) # Check allowed senders
      true
    end

    #
    # Process message to build params hash and pass message along with params of
    # to +handle+
    #
    def dispatch(message)
      return unless recognize?(message)
      params = {}

      if @pattern && @tokens
        matches = message.text.match(@pattern)
        @tokens.each_with_index {|token, i| params[token] = matches[i+1] }
        params[:text] = (matches[@tokens.length+1] || '').strip
      elsif @pattern && !@tokens
        params = message.text.match(@pattern).to_a[1..-1] || []
      else
        params[:text] = message.text
      end

      return handle(message, params)
    end

    #
    # Handle a message. Calls the internal Proc with the message and the params
    # hash as parameters.
    #
    def handle(message, params)
      @handler.call(message, params) if @handler
    end
  end
end

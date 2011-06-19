module Jabbot
  module Handlers
    # Public: Add a handler for a given type.
    #
    # type    - The Symbol representation of the type to be handled.
    # handler - The Jabbot::Handler instance to handle a message.
    #
    # Returns the handler.
    def add_handler(type, handler)
      handlers[type] << handler
      handler
    end

    # Public: Dispatch a message based on is type.
    #
    # type    - The Symbol representation of the type to be dispatched.
    # message - The String message to be handled.
    #
    # Returns nothing.
    def dispatch(type, message)
      handlers[type].each {|handler| handler.dispatch(message) }
    end

    # Internal: Setup Arrays of all handler types.
    #
    # Returns a Hash containing the possible handler types and
    #  its associated Arrays of handlers.
    def handlers
      @handlers ||= {
        :message => [],
        :private => [],
        :join => [],
        :subject => [],
        :leave => []
      }
    end

    # Deprecated: Set the handler types and Arrays
    #
    # hash - A hash containing the handler types and associated Arrays
    #        (see `handlers`).
    #
    # Returns nothing.
    def handlers=(hash)
      @handlers = hash
    end
  end

  # A Handler consists of a pattern to match a given message,
  # some options and a handler block to be called on dispatch.
  #
  class Handler
    # Public: Initialize a new handler instance.
    #
    # pattern - The String, Symbol or Regexp pattern to match the messages
    #           against or a Hash (default: nil).
    #           If pattern is a Hash containing just one key :exact,
    #           its value is used as the pattern and should therefore be
    #           a String or Regexp.
    #           If the pattern is a Hash, but not containing
    #           the key :exact, the pattern is set to nil
    #           and the passed value is re-used as `options`.
    #           A pattern of nil will match every message.
    # options - The Hash options to refine the handler (default: {})
    #           :from - A String, Symbol or Array of usernames to
    #                   accept messages from
    #           *     - Any String here is later used in the pattern
    #                   parsing and its value is used as a replacement
    #                   of the pattern parameter and should be a
    #                   valid String to be used in a Regexp,
    #                   containing just one match group.
    # blk     - The block to handle a pattern-matched message
    #           and respond to it.
    #           It will be passed to arguments:
    #             message - The actual Message struct.
    #             params  - An Array of matched params if any.
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
      self.pattern = pattern ? pattern.dup : pattern
    end

    # Internal: Parse pattern string and set parameter options.
    #
    # There are a few special cases:
    #
    # If the pattern is nil, empty or the Symbol :all, the handler is
    # dispatched on all incoming messages for the given type.
    #
    # If the pattern is a Regexp it is used as-is.
    #
    # If the pattern is a String or any other Symbol (coerced to a String)
    # it is parsed.
    #
    # Parsing:
    #
    # Every word in the pattern starting with a colon (:) and followed by
    # any non-whitespace characters is used as a parameter match name.
    #
    # Matched pattern names are then replaced to match any
    # non-whitespace character by default.
    # Otherwise defined patterns may be used instead.
    #
    # If @exact_match is set, the resulting pattern is nested
    # between \A and \Z to match a whole string without
    # leading or trailing characters.
    #
    # Example:
    #
    #     handler.pattern = "Welcome :me"
    #     # => /Welcome ([^\s]+)/
    #
    #     handler.pattern = "Welcome :me" # with @exact_match = true
    #     # => /\AWelcome ([^\s]+)\Z/
    #
    #     options = { "me" => "([aeiou]+)" }
    #     handler.pattern = "Welcome :me"
    #     # => /Welcome ([aeiou]+)/
    #
    # Returns nothing.
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

    # Public: Get the pattern RegExp.
    attr_reader :pattern

    # Internal: Determines if this handler is suited to handle
    #           an incoming message.
    #
    # Returns a Boolean if it recognized the given message.
    def recognize?(message)
      return false if @pattern && message.text !~ @pattern

      users = @options[:from] ? @options[:from] : nil
      return false if users && !users.include?(message.user) # Check allowed senders
      true
    end

    # Public: Process a message to build params hash and handle it.
    #
    # message - The incoming String message.
    #
    # Returns the response from `handle`.
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

      handle(message, params)
    end

    # Internal: Call the assigned message handler if any.
    #
    # message - The incoming String message.
    # params  - The hash containing matched tokens.
    #
    # Returns the return from the handler block.
    def handle(message, params)
      @handler.call(message, params) if @handler
    end
  end
end

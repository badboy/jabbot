module Jabbot
  # Defines the DSL used for bots.
  module Macros
    def self.included(mod)
      @@bot = nil
    end

    # Configure the bot
    # The block gets passed an instance of OpenStruct used as the config
    # See lib/jabbot/config.rb for possible options
    def configure(&blk)
      bot.configure(&blk)
    end

    # Returns the current config hash
    def config
      bot.config
    end

    # Add message handler
    # pattern - can be a String containing :matches
    #           or a Regexp with matching groups
    # options - Hash defining users to receive messages from
    #           { :from => ['user1', 'user2', ...] }
    # blk     - The block to execute on successfull match
    def message(pattern = nil, options = {}, &blk)
      add_handler(:message, pattern, options, &blk)

      # if :query => true, add this block for queries, too
      add_handler(:private, pattern, options, &blk) if options && options[:query]
    end

    # Add query handler
    # Only private messages are matched against this handler
    #
    # pattern - can be a String containing :matches
    #           or a Regexp with matching groups
    # options - Hash defining users to receive messages from
    #           { :from => ['user1', 'user2', ...] }
    # blk     - The block to execute on successfull match
    def query(pattern = nil, options = {}, &blk)
      add_handler(:private, pattern, options, &blk)
    end
    alias_method :private_message, :query

    # Add join handler
    # Block gets executed when new user joins
    #
    # options - Hash defining users to react on joins
    #           { :from => ['user1', 'user2', ...] }
    # blk     - The block to execute on successfull match
    def join(options = {}, &blk)
      add_handler(:join, /\Ajoin\Z/, options, &blk)
    end

    # Add leave handler
    # Block gets executed when user leaves the channel
    #
    # options - Hash defining users to react on leaves
    #           { :from => ['user1', 'user2', ...] }
    # blk     - The block to execute on successfull match
    def leave(options = {}, &blk)
      add_handler(:leave, /\Aleave\Z/, options, &blk)
    end

    # Add subject/topic handler
    # Block gets executed when topic gets changed
    #
    # pattern - can be a String containing :matches
    #           or a Regexp with matching groups
    # options - Hash defining users
    #           { :from => ['user1', 'user2', ...] }
    # blk     - The block to execute on successfull match
    def subject(pattern = nil, options = {}, &blk)
      add_handler(:subject, pattern, options, &blk)
    end
    alias_method :topic, :subject

    # Returns the Jabber::Client instance used
    # You may execute low-level functions on this object if needed
    def client
      bot.client
    end

    # Close the connection and exit the bot
    def close
      bot.close
    end
    alias_method :quit, :close

    # Get array of all users in the channel
    def users
      bot.users
    end

    # Post message back to the channel
    # msg - Message to send, can be a String to be send
    #       or a Hash: { msg => user }
    # to  - User to send the message to,
    #       left blank if syntax-sugar variant is used
    #
    # Syntax-sugar variant:
    #   post "msg" => "user1"
    # is the same as
    #   post "msg", "user1"
    def post(msg, to=nil)
      if msg.is_a?(Hash) && msg.keys.size == 1
        to = msg.values.first
        msg = msg.keys.first
      elsif to.kind_of?(Struct)
        if to.type == :query
          to = to.user
        else
          to = nil
        end
      end
      bot.send_message(msg, to)
    end

    # Returns boolean wether to start the bot at_exit
    def run?
      !@@bot.nil?
    end

    private

    # Low-level method to add new Handler to the bot
    def add_handler(type, pattern, options, &blk)
      bot.add_handler(type, Jabbot::Handler.new(pattern, options, &blk))
    end

    # Low-level method to create new instance of a bot
    def bot
      return @@bot unless @@bot.nil?

      begin
        @@bot = Jabbot::Bot.new nil
      rescue Exception
        @@bot = Jabbot::Bot.new(Jabbot::Config.default)
      end

      @@bot
    end

    def self.bot=(bot)
      @@bot = bot
    end
  end
end

module Jabbot
  @@prompt = false

  def self.prompt=(p)
    @@prompt = f
  end

  module Macros
    def self.included(mod)
      @@bot = nil
    end

    def configure(&blk)
      bot.configure(&blk)
    end

    def message(pattern = nil, options = {}, &blk)
      add_handler(:message, pattern, options, &blk)
    end

    def query(pattern = nil, options = {}, &blk)
      add_handler(:private, pattern, options, &blk)
    end
    alias_method :private_message, :query

    def join(options = {}, &blk)
      add_handler(:join, /\Ajoin\Z/, options, &blk)
    end

    def leave(options = {}, &blk)
      add_handler(:leave, /\Aleave\Z/, options, &blk)
    end

    def subject(pattern = nil, options = {}, &blk)
      add_handler(:subject, pattern, options, &blk)
    end
    alias_method :topic, :subject

    def client
      bot.client
    end

    def close
      bot.close
    end
    alias_method :quit, :close

    def user
      bot.user
    end

    def post(msg, to=nil)
      if msg.is_a?(Hash) && msg.keys.size == 1
        to = msg.values.first
        msg = msg.keys.first
      end
      bot.send_message(msg, to)
    end

    def run?
      !@@bot.nil?
    end

   private
    def add_handler(type, pattern, options, &blk)
      bot.add_handler(type, Jabbot::Handler.new(pattern, options, &blk))
    end

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

# -*- encoding: utf-8 -*-

require './lib/jabbot/version'

Gem::Specification.new do |s|
  s.name           = "jabbot"
  s.version        = Jabbot::VERSION
  s.date           = Time.now.strftime("%Y-%m-%d")
  s.summary        = "Simple framework for creating Jabber/MUC bots, inspired by Sinatra and Twibot"
  s.homepage       = "http://github.com/badboy/jabbot"
  s.email          = "badboy@archlinux.us"
  s.authors        = ["badboy"]
  s.has_rdoc       = false
  s.require_path   = "lib"
  s.files          = %w( README.md Rakefile LICENSE )
  s.files         += Dir.glob("lib/**/*")
  s.files         += Dir.glob("test/**/*")
  s.description    = <<-desc
  Jabbot is a Ruby micro-framework for creating Jabber/MUC bots,
  heavily inspired by Sinatra and Twibot.

  I modified the code of Twibot to fit my needs.
  The original Twibot code by Christian Johansen is located at:
  http://github.com/cjohansen/twibot

  It's as easy as definig a small message handler:
    message {|message, params|
      post message.text
    }
  desc

  s.add_dependency('xmpp4r', '~>0.4')
  s.add_dependency('eventmachine', '~>0.12')
  s.add_development_dependency('shoulda', '~>2.10.1')
end

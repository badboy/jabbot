# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name           = "jabbot"
  s.version        = "0.3.1"
  s.date           = "2011-04-12"
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
  The original Twibot code is located at:
  http://github.com/cjohansen/twibot/tree/master

  A big thank you to Christian Johansen, who wrote the code for Twibot.
  Jabbot is heavily based on his code.

  It's as easy as definig a small message handler:
    message do |message, params|
      post message.text
    end
  desc

  s.add_dependency('xmpp4r', '~>0.4')
  s.add_dependency('eventmachine', '~>0.12'
  s.add_development_dependency('shoulda', '>=2.10.1')
end

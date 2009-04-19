# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jabbot}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["BadBoy_"]
  s.date = %q{2009-04-19}
  s.email = %q{badboy@archlinux.us}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/hash.rb",
    "lib/jabbot.rb",
    "lib/jabbot/bot.rb",
    "lib/jabbot/config.rb",
    "lib/jabbot/handlers.rb",
    "lib/jabbot/macros.rb",
    "lib/jabbot/message.rb",
    "test/test_bot.rb",
    "test/test_config.rb",
    "test/test_handler.rb",
    "test/test_hash.rb",
    "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/badboy/jabbot}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Simple framework for creating Jabber/MUC bots, inspired by Sinatra and Twibot}
  s.test_files = [
    "test/test_helper.rb",
    "test/test_bot.rb",
    "test/test_hash.rb",
    "test/test_config.rb",
    "test/test_handler.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<xmpp4r>, [">= 0.4"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 2.10.1"])
      s.add_development_dependency(%q<jeweler>, [">= 0.10.2"])
    else
      s.add_dependency(%q<xmpp4r>, [">= 0.4"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 2.10.1"])
      s.add_dependency(%q<jeweler>, [">= 0.10.2"])
    end
  else
    s.add_dependency(%q<xmpp4r>, [">= 0.4"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 2.10.1"])
    s.add_dependency(%q<jeweler>, [">= 0.10.2"])
  end
end

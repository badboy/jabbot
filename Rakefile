require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "jabbot"
    gem.summary = %Q{Simple framework for creating Jabber/MUC bots, inspired by Sinatra and Twibot}
    gem.email = "badboy@archlinux.us"
    gem.homepage = "http://github.com/badboy/jabbot"
    gem.authors = ["BadBoy_"]
    gem.add_dependency('xmpp4r', '>=0.4')
    gem.add_development_dependency('thoughtbot-shoulda', '>=2.10.1')
    gem.add_development_dependency('technicalpickles-jeweler', '>=0.10.2')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = false
end

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "jabbot #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


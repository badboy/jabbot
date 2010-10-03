begin
  require 'mg'
rescue LoadError
  abort "Please `gem install mg`"
end

MG.new("jabbot.gemspec")

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = false
end

task :default => :test

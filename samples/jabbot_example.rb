#!/usr/bin/env ruby

require 'rubygems'
require 'jabbot'

configure do |conf|
  conf.login = 'login@server.tld'
  conf.channel = 'jabbot_test'
  conf.server = 'conference.server.tld'
  conf.password = 'secret'
end

message do |message, params|
  puts message
end

message :from => [:abcd, :efgh] do |message, params|
  post "I agree!" => message.user
end

query /\A.quit\Z/, :from => :admin do |message, params|
  post "good bye! I'm going to sleep"
  close
end

message ".answer :me" do |message, params|
  post "ok, the answer is: #{params[:me]}"
end

message :exact => "!exit" do |message, params|
  post "Bye Bye!"
  close
end

## You need a extern Google engine
## write your own or search github.com / rubyforge.org
#message /\A\.google (.+)/im do |message, params|
#  search_result = MyGoogleSearch.lookup(params.first)
#  post "Google Search for '#{params.first}':\n#{search_result}"
#end

leave do |message, params|
  post "and there he goes...good bye, #{message.user}"
end

join do |message, params|
  post "Hi, #{message.user}. How are you?"
end

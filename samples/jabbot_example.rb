#!/usr/bin/env ruby

require 'rubygems'
require 'jabbot'

configure do |conf|
  conf.login = 'login@server.tld'
  conf.channel = 'jabbot_test'
  conf.server = 'conference.server.tld'
  conf.password = 'secret'
end

# Just print all incoming messages to stdout.
message do |message, params|
  puts message
end

# Agree to certain users, no matter what they said.
message :from => [:abcd, :efgh] do |message, params|
  post "I agree!" => message.user
end

# The user 'admin' can quit the bot via private message.
query /\A!quit\Z/, :from => :admin do |message, params|
  post "good bye! I'm going to sleep" => message.user
  close
end

# Same as query above, but for all users and global messages.
message :exact => "!quit" do |message, params|
  post "Bye Bye!"
  close
end

# Respond with whatever was given as the answer.
message ".answer :me" do |message, params|
  post "ok, the answer is: #{params[:me]}"
end

## You need a extern Google engine
## write your own or search github.com
message /\A!google (.+)/im do |message, params|
  search_result = MyGoogleSearch.lookup(params.first)
  post "Google Search for '#{params.first}':\n#{search_result}"
end

leave do |message, params|
  post "and there he goes...good bye, #{message.user}"
end

join do |message, params|
  post "Hi, #{message.user}. How are you?"
end

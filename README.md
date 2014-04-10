# Jabbot

## Description

Jabbot is a Ruby micro-framework for creating Jabber/MUC bots, heavily inspired by Sinatra and Twibot.

I modified the code of Twibot to fit my needs. The original Twibot code is located at: <http://github.com/cjohansen/twibot>

A big thank you to Christian Johansen, who wrote the code for Twibot. Jabbot is heavily based on his code.

If your curious if this code is stable enough:
I have a bot instance running on my server for years now and it works great :)

Just keep in mind that the code is not the most beautiful, maybe has bugs or rough edges. Feel free to improve it. I use it as is.


## Usage

### Simple example

~~~ruby
configure do |conf|
  conf.login    = "my_account"
  conf.password = "my_account"
  conf.nick     = "mybot"
  conf.channel  = "mychannel"
end

# Receive messages, and post them publicly
message do |message, params|
  post message.text
end

# Respond to query if they come from the right crowd
# query "message" => "user" is just some syntax sugar
# query "message", "user" will work, too
query :from => [:cjno, :irbno] do |message, params|
  post "#{message.user} I agree" => message.user
end

# Log every single line
# (you can use "message :all" too ;)
message do |message, params|
  MyApp.log_message(message)
end
~~~

### Running the bot

To run the bot, simply do:

~~~
ruby bot.rb
~~~

Jabbot uses the [at\_exit hook](http://ruby-doc.org/core/classes/Kernel.html#M005932) to start.

### Configuration

You have to configure your bot via ruby:

~~~ruby
configure do |conf|
  conf.login = "my_account"
  conf.nick = "mybot"
end
~~~

If you don't specify login and/or password in any of these ways, Jabbot will fail. The nick is automatically set to "jabbot" unless something different is defined. If you want you can set the XMPP Resource:

~~~ruby
configure do |conf|
  conf.resource ="mybot_resource"
end
~~~

Default resource is "jabbot".

### "Routes"

Like Sinatra, and other web app frameworks, Jabbot supports "routes":
patterns to match incoming messages:

    message "time :country :city" do |message, params|
      time = MyTimeService.lookup(params[:country], params[:city])
      post "Time is #{time} in #{params[:city]}, #{params[:country]}"
    end

You can have several "message" blocks (or "join", "leave", "query" or "subject").
Every matching block will be called.

Jabbot also supports regular expressions as routes:

~~~ruby
message /^time ([^\s]*) ([^\s]*)/ do |message, params|
  # params is an array of matches when using regexp routes
  time = MyTimeService.lookup(params[0], params[1])
  post "Time is #{time} in #{params[:city]}, #{params[:country]}"
end
~~~

If all you need is exact word matching you can say so:

~~~ruby
message :exact => "pattern" do |message, params|
  ...
end
~~~

Internally this pattern is translated to `/\Apattern\Z/`, so you can use regex literals.

## Requirements

* xmpp4r. You'll need atleast 0.4. You can get it via rubygems: `gem install xmpp4r`
* eventmachine. `gem install eventmachine`


## Installation

Jabbot is available via gem:

~~~
gem install jabbot
~~~

## Is it Ruby 1.9?

Absolutely! I run it on 1.9.3 without problems (thanks to the updated xmpp4r).

## Is it Ruby 2.x?

It should, test pass. I'm not sure if it will work as expected.

## Samples

There are two examples in the [samples][] directory:

* [jabbot_example.rb][] is a working sample without real functionality.
* [black.rb][] is the code I use for my own bot (without the config of course).

## Contributors

* Christian Johansen (cjohansen) (author of Twibot) - http://www.cjohansen.no

## License

The code is released under the MIT license. See [LICENSE][].

## Contribute

If you'd like to hack on jabbot, start by forking my repo on GitHub:

http://github.com/badboy/jabbot

Then:

1. Clone down your fork
2. Create a thoughtfully named topic branch to contain your change
3. Hack away
4. Add tests and make sure everything still passes by running `rake`
5. If you are adding new functionality, document it in the README
6. Do not change the version number, I will do that on my end
7. If necessary, rebase your commits into logical chunks, without errors
8. Push the branch up to GitHub
9. Send me (badboy) a pull request for your branch

[LICENSE]: http://github.com/badboy/jabbot/blob/master/LICENSE
[jabbot_example.rb]: http://github.com/badboy/jabbot/blob/master/samples/jabbot_example.rb
[black.rb]: http://github.com/badboy/jabbot/blob/master/samples/black.rb

#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'jabbot'
require 'json'
require 'net/http'
require 'open-uri'
require 'uri'
require 'time'
require 'nokogiri'

BLOCKED_HOSTS = %w[ localhost 127.0.0.1 ]

DEFAULT_ENCODINGS = %w[ utf8 utf-8 UTF8 UTF-8 ]

load "./_config.rb"

def log(com, msg)
  $stderr.puts "#{msg.time} | #{com} | <#{msg.user}> #{msg.text}"
end

TITLE_MAX_LENGTH = 100

TWITTER_BASE   = "http://twitter.com/statuses/show/"
TWITTER_FORMAT = "json"
IDENTI_BASE    = "http://identi.ca/api/statuses/show/"
IDENTI_FORMAT  = "json"

TWITTER_REGEX  = /https?:\/\/twitter.com\/[^\/]+\/status\/(\d+)/
TWITTER_FAIL   = "Twitter hat nicht sinnvolles geantwortet. Hey. Guck nicht so! DIE sind schuld."
IDENTI_REGEX   = /https?:\/\/identi.ca\/notice\/(\d+)/
IDENTI_FAIL    = "Identica hat nicht sinnvolles geantwortet. Hey. Guck nicht so! DIE sind schuld."

def twitter(params)
  twitter_id = nil
  params[:id].gsub!(/\s/, '')
  if params[:id] =~ TWITTER_REGEX
    twitter_id = $1
  elsif !(params[:id] =~ /\A\d+\z/)
    return "Eine Twitter-ID besteht nur aus Zahlen, also gib mir auch so eine."
  else
    twitter_id = params[:id]
  end

  if twitter_id
    begin
      resp = open("#{TWITTER_BASE}#{twitter_id}.#{TWITTER_FORMAT}").read
      json = JSON.parse(resp)
      time = Time.parse(json["created_at"]).strftime("%d.%m.%Y %H:%M")
      user = json["user"]["screen_name"]
      mess = json["text"]

      "[#{time}] #{user}: #{mess}"
    rescue OpenURI::HTTPError => e
      "Ok. Der User will nicht, dass wir seine Tweets lesen. Der ist also voll unrelevant!"
    end
  end
end

def identi(params)
  identi_id = nil
  params[:id].gsub!(/\s/, '')
  if params[:id] =~ IDENTI_REGEX
    identi_id = $1
  elsif !(params[:id] =~ /\A\d+\z/)
    return "Eine Identi.ca-ID besteht nur aus Zahlen, also gib mir auch so eine."
  else
    identi_id = params[:id]
  end

  if identi_id
    resp = open("#{IDENTI_BASE}#{identi_id}.#{IDENTI_FORMAT}").read
    json = JSON.parse(resp)
    time = Time.parse(json["created_at"]).strftime("%d.%m.%Y %H:%M")
    user = json["user"]["screen_name"]
    mess = json["text"]

    "[#{time}] #{user}: #{mess}"
  end
end

message "!tw :id" do |message, params|
  begin
    log("!tw", message)
    msg = twitter(params)
    post msg ? msg : TWITTER_FAIL
  rescue Exception => e
    puts e
    puts e.backtrace
    post "Sorry, irgendwas ist schief gelaufen..."
  end
end

message "!identi :id" do |message, params|
  begin
    log("!identi", message)
    msg = identi(params)
    post msg ? msg : IDENTI_FAIL
  rescue Exception => e
    puts e
    puts e.backtrace
    post "Sorry, irgendwas ist schief gelaufen..."
  end
end

message "!help" do |message, params|
  log("!help", message)

  post <<-COM
Folgende Kommandos stehen zur Verfügung:
  !tw <id>
  !identi <id>
  COM
end

message(/^#{bot.config[:nick]}\?$/) do |message, params|
  log("#{bot.config[:nick]}?", message)
  post "Anwesend. Gibt's was zu tun?"
end

# example taken from
# http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html
# handles redirects correctly
def fetch(uri_str, limit = 10)
  # You should choose better exception.
  #  Nope, I won't.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  response = Net::HTTP.get_response(uri_str.kind_of?(URI) ? uri_str : URI.parse(uri_str))
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  else
    response.error!
  end
end

message(/(https?:\/\/\S+)/) do |message, params|
  begin
    next if message.text =~ /\A\s*!\w+/

    log("link", message)

    uri = URI.parse(params[0])
    if !BLOCKED_HOSTS.include?(uri.host)
      case uri.to_s
      when TWITTER_REGEX
        $stderr.puts "it's a twitter url! fetch it!"
        msg = twitter({:id => uri.to_s})
        post msg ? msg : TWITTER_FAIL
      when IDENTI_REGEX
        msg = identi({:id => uri.to_s})
        post msg ? msg : IDENTI_FAIL
      else
        req = fetch(uri) # handle redirects
        doc = Nokogiri::HTML(req.body)
        if req.header['content-type'] =~ /text/i
          http_equiv = doc.css("meta[http-equiv=content-type]").first
          if http_equiv && content = http_equiv.attributes['content']
            send_encoding = content.to_s.gsub(/^.+charset=/, '')
          end

          if !send_encoding && req.header['content-type'] =~ /^.+charset=(.+)/i
            send_encoding = $1
          end

          if doc && title = doc.css("title")
            if !title.empty?
              title = title[0].content.gsub(/\r/, '').gsub(/\n/, ' ').gsub(/\s+/, ' ')
              if title.length > TITLE_MAX_LENGTH
                title = title[0, TITLE_MAX_LENGTH] + '...'
              end

              if send_encoding && !DEFAULT_ENCODINGS.include?(send_encoding)
                title = Iconv.iconv(DEFAULT_ENCODINGS.first, send_encoding, title)[0]
              end

              post "Titel: #{title} (at #{uri.host} )"
            else
              post "Titel: <empty> (at #{uri.host} )"
            end
          end
        end
      end
    end

  rescue SocketError => e
    if e.message == "getaddrinfo: No address associated with hostname"
      post "Die angegebene Seite existiert nicht."
    else
      $stderr.puts "We're on line #{__LINE__}"
      $stderr.puts e.inspect
      $stderr.puts uri.inspect
      $stderr.puts message.inspect
    end
  rescue Exception => e
    $stderr.puts "We're on line #{__LINE__}"
    $stderr.puts e.inspect
    $stderr.puts uri.inspect
    $stderr.puts message.inspect
  end
end

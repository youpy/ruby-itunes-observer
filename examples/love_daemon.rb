#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# OSX only

require 'rubygems'
require 'lastfm'
require 'pit'

$KCODE = "UTF8"

def main
  config = Pit.get("last.fm", :require => {
      "api_key" => "your api key in last.fm",
      "api_secret" => "your api secret in last.fm"
    })

  lastfm = Lastfm.new(
    config['api_key'],
    config['api_secret'])

  unless session = config['session']
    token = lastfm.auth.get_token
    auth(config['api_key'], token)
    session = lastfm.auth.get_session(token)
    Pit.set('last.fm', :data => {
        "session" => session
      }.merge(config))

    puts "Session key was generated."

    return
  end

  lastfm.session = session

  exit if fork
  Process.setsid
  File.open("/dev/null") {|f|
    STDIN.reopen f
    STDOUT.reopen f
    STDERR.reopen f
  }

  require 'itunes_observer'

  ITunesObserver.new {|result|
    name = result['Name']
    artist = result['Artist']
    rating = result['Rating']

    if rating.to_i > 80
      begin
        lastfm.track.love(artist, name)
      rescue
      end
    end
  }.run
end

def auth(api_key, token)
  auth_url = 'http://www.last.fm/api/auth/?api_key=' + api_key + '&token=' + token

  unless system('open', auth_url)
    print 'open ' + auth_url + ' in your browser and '
  end

  print 'after authorization, push any key:'
  STDIN.gets.chomp
  puts
end

main

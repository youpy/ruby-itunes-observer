#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# OSX only

require 'rubygems'
require 'json'
require 'pp'
require 'digest/md5'
require 'net/https'
require 'pit'
require 'cgi'

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
    token = lastfm.get_token
    auth(lastfm.api_key, token)
    session = lastfm.get_session(token)
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
        lastfm.love(artist, name)
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

class Lastfm
  attr_reader :api_key, :api_secret
  attr_writer :session

  def initialize(api_key, api_secret, connection =
      REST::Connection.new('http://ws.audioscrobbler.com/2.0/'))
    @api_key = api_key
    @api_secret = api_secret
    @connection = connection
    @session = nil
  end

  def get_token
    request('auth.getToken')['token']
  end

  def get_session(token)
    response = request('auth.getSession', {
        :token => token,
      })

    response['session']['key']
  end

  def love(artist, name)
    # FIXME: response format will not be JSON...API bug?
    request('track.love', {
        :track => name,
        :artist => artist,
        :sk => @session
      }, 'post')
  end

  private

  def request(method, params = {}, http_method = 'get')
    params[:method] = method
    params[:api_key] = @api_key
    # http://www.lastfm.jp/group/Last.fm+Web+Services/forum/21604/_/497978
    #params[:format] = format

    sig = params.to_a.sort_by do |param|
      param.first.to_s
    end.inject('') do |result, param|
      result + param.join('')
    end + @api_secret

    params.update(:api_sig => Digest::MD5.hexdigest(sig), :format => 'json')

    json = JSON.parse(@connection.send(http_method, '', params))
    pp json
    json
  end
end

module REST
  class Connection
    def initialize(base_url)
      @base_url = base_url
    end

    def get(resource, args = nil)
      url = URI.join(@base_url, resource)

      if args
        url.query = query(args)
      end

      req = Net::HTTP::Get.new(url.request_uri)
      request(req, url)
    end

    def post(resource, args = nil)
      url = URI.join(@base_url, resource)

      req = Net::HTTP::Post.new(url.request_uri)

      if args
        req.body = query(args)
      end

      request(req, url)
    end

    def request(req, url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.port == 443)

      res = http.start() { |conn| conn.request(req) }
      res.body
    end

    def query(params)
      params.map { |k,v| "%s=%s" % [CGI.escape(k.to_s), CGI.escape(v.to_s)] }.join("&")    
    end
  end
end

main

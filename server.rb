# server.rb

require "cuba"
require "rack/protection"
require "json"
require 'rest-client'
require "useragent"
require "securerandom"

def get_key(kf)
  STDERR.puts "getting key \"#{kf}\""
  kb_uri = "https://keybase.io/_/api/1.0/user/user_search.json?q=#{kf}&num_wanted=2"
  user_response = RestClient.get(kb_uri)
  data = JSON.parse(user_response.body)

  if data['list'].count == 0
    STDERR.puts 'Error: no users found'
    return nil
  elsif data['list'].count > 1
    STDERR.puts 'Error: more than one user found'
    return nil
  end

  keybase_username = data['list'].first['keybase']['username']
  key_response = RestClient.get("https://keybase.io/#{keybase_username}/pgp_keys.asc")

  return key_response.body
end

def cli?(user_agent)
  return true if UserAgent.parse(user_agent).browser =~ /(wget)|(curl)/i
  return false
end

def pre_wrap(string)
  return "<pre>#{string}</pre>"
end

def auto_wrap(results)
  return cli?(req.user_agent) ? results + "\n" : pre_wrap(results)
end

Cuba.define do
  on get do
    # /favicon.ico
    on "favicon.ico" do
      res.status = 404
      res.write "#### 404 ####"
      res.finish
    end
    on root do
      results = 'try "/pks/lookup?op=get&options=mr&search=0x"'
      res.write cli?(req.user_agent) ? results + "\n" : pre_wrap(results)
    end
    on "pks/lookup" do
      q = env['QUERY_STRING'].split('&').map{|k| k.split('=') }.to_h
      search = q['search'] || nil
      op = q['op'] || nil
      if search.nil? || search.empty?
        res.status = 404
        results = "No search field in queryString"
      else
        user_key = get_key(search[/(?<=^0x).*/])
        res.status = 404 if user_key.nil?
        results = user_key
      end
      res.write results
    end
  end
end

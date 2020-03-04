# server.rb

require "cuba"
require "rack/protection"
require "json"
require 'rest-client'
require "useragent"
require "securerandom"

def get_key(kf)
  STDERR.puts "getting key \"#{kf}\""
  kb_uri = "https://keybase.io/_/api/1.0/user/lookup.json?fields=public_keys&key_fingerprint=#{kf}"
  user_response = RestClient.get(kb_uri)
  data = JSON.parse(user_response.body)

  if data['them'].count == 0
    STDERR.puts 'Error: no results'
    return nil
  elsif data['them'].count > 1
    STDERR.puts 'Error: more than one result returned'
    return nil
  end

  public_keys = data['them'].first['public_keys'].select do |k,v|
    v.class == Hash && v["key_fingerprint"] == kf.downcase
  end

  if public_keys.count == 0
    STDERR.puts 'Error: no public keys'
  elsif public_keys.count > 1
    STDERR.puts 'Error: more than one public key'
  end

  # in case we're looking for non-primary key
  public_key = public_keys.flatten.select do |k|
    k.class == Hash && k['key_fingerprint'] == kf.downcase
  end

  public_key_data = public_key.first['bundle']

  return public_key_data
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

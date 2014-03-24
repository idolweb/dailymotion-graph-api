require "dailymotion-graph-api/version"
require 'faraday'
require 'json'

module DailymotionGraphApi
  class Client
    def initialize(client_id, client_secret, access_token = nil, refresh_token = nil)
      @client_id      = client_id
      @client_secret  = client_secret
      @access_token   = access_token
      @refresh_token  = refresh_token
    end

    def authorize_url(callback_url)
      "https://api.dailymotion.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{callback_url}&response_type=code"
    end

    def connexion
      @connexion ||= Faraday.new(:url => 'https://api.dailymotion.com', :ssl => {:verify => false}) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def refresh_token
      result = connexion.post do |request|
        request.url     '/oauth/token'
        request.body  = {
          grant_type:     'refresh_token',
          client_id:      @client_id,
          client_secret:  @client_secret,
          refresh_token:  @refresh_token
        }
      end

      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      @access_token   = r['access_token']
      @refresh_token  = r['refresh_token']

      r
    end

    def get_access_token(code, callback_url)
      result = connexion.post do |request|
        request.url     '/oauth/token'
        request.body  = {
          grant_type:     'authorization_code',
          client_id:      @client_id,
          client_secret:  @client_secret,
          redirect_uri:   callback_url,
          code:           code
        }
      end

      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      @access_token   = r['access_token']
      @refresh_token  = r['refresh_token']

      r
    end
    
    def get_infos(user, additional_params = {})
      raise "Access token is required" if @access_token.nil?

      result = connexion.get do |request|
        request.url     "/user/#{user}"
        request.params  = {
          access_token:   @access_token
        }.merge(additional_params)
      end

      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      r
    end
  end
end

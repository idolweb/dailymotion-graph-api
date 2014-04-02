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
      "https://api.dailymotion.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{callback_url}&response_type=code&scope=manage_videos"
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
    
    def tmp_upload(video_path)
      remote_uri = URI.parse(get_upload_url['upload_url'])
      
      upload_connexion = Faraday.new(:url => 'http://upload-01.dailymotion.com', :ssl => {:verify => false}) do |faraday|
        faraday.request  :multipart
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
      
      result = upload_connexion.post do |request|
        request.url     '/upload'
        request.params  = remote_uri.query.split('&').collect{|item| item.split('=')}.to_h # surement plus élégant à faire
        request.body    = {
          file: Faraday::UploadIO.new(video_path, 'video/mp4')
        }
      end
      
      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      r
    end
    
    def create_video(arguments)
      result = connexion.post do |request|
        request.url     '/me/videos'
        request.params  = {
          access_token:   @access_token
        }
        request.body    = arguments
      end
      
      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      r
    end
    
    
    def get_upload_url
      result = connexion.get do |request|
        request.url     '/file/upload'
        request.params  = {
          access_token:   @access_token
        }
      end
      
      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

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

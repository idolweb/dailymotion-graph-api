require 'dailymotion-graph-api/version'
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

    def authorize_url(callback_url, scope_array = %w(manage_videos))
      "https://api.dailymotion.com/oauth/authorize?client_id=#{@client_id}&redirect_uri=#{callback_url}&response_type=code&scope=#{scope_array.join('+')}"
    end

    def connexion
      @connexion ||= Faraday.new(:url => 'https://api.dailymotion.com', ssl: { verify: false }) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
    end

    def refresh_token
      raise 'Missing refresh token' unless @refresh_token
      token('refresh_token', refresh_token: @refresh_token)
    end

    def get_access_token(code, callback_url)
      token('authorization_code', redirect_uri: callback_url, code: code)
    end

    def tmp_upload(video_path)
      remote_uri = URI.parse(get_upload_url['upload_url'])

      upload_connexion = Faraday.new(url: 'http://upload-01.dailymotion.com', ssl: { verify: false }) do |faraday|
        faraday.request  :multipart
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      send_request('/upload', remote_uri.query.split('&').collect{|item| item.split('=')}.to_h.merge(
          { body: {
              file: Faraday::UploadIO.new(video_path, 'video/mp4')
            },
            connexion: upload_connexion
          })
        )
    end

    def create_video(arguments)
      send_request('/me/videos', { verb: :post, body: arguments })
    end

    def videos(user, fields = %w(id title created_time))
      has_more = true
      page = 1
      result = []
      while has_more
        response = send_request("/user/#{user}/videos", limit: 100, page: page, fields: fields.join(','))
        result += response['list']
        has_more = response['has_more']
        page += 1
      end
      result
    end

    def get_upload_url
      send_request('/file/upload')
    end

    def get_infos(user, additional_params = {})
      send_request("/user/#{user}", additional_params)
    end

    private

    DEFAULTS = {
        verb: :get,
        auth: true
    }

    def send_request(url, options = {})
      options = DEFAULTS.merge(options)
      verb = options.delete(:verb)
      body = options.delete(:body)
      auth = options.delete(:auth)
      connexion = options.delete(:connexion) || self.connexion

      if auth
        if @access_token
          options[:access_token] = @access_token
        else
          raise 'Access token is required'
        end
      end

      result = connexion.send(verb) do |request|
        request.url     url
        request.params = options
        request.body = body if body
      end

      r = JSON.parse(result.body)
      if r.keys.include?('error')
        raise "#{r['error']}: #{r['error_description']}"
      end

      r
    end

    def token(grant_type, args = {})
      r = send_request('/oauth/token', { verb: :post, auth: false, body: {
            grant_type:     grant_type,
            client_id:      @client_id,
            client_secret:  @client_secret
          }.merge(args)
        })

      @access_token   = r['access_token']
      @refresh_token  = r['refresh_token']

      r
    end
  end
end

require 'addressable/uri'
require 'base64'
require 'simple_oauth'

module Twitter
  class Headers
    def initialize(client, request_method, url, options = {})
      @client = client
      @request_method = request_method.to_sym
      @uri = Addressable::URI.parse(url)
      @bearer_token_request = options.delete(:bearer_token_request)
      @gzip_request = options.delete(:gzip_request)
      @options = options
    end

    def bearer_token_request?
      !!@bearer_token_request
    end

    def gzip_request?
      !!@gzip_request
    end

    def oauth_auth_header
      SimpleOAuth::Header.new(@request_method, @uri, @options, credentials)
    end

    def request_headers
      headers = {}
      headers[:user_agent] = @client.user_agent

      if gzip_request?
        headers[:accept_encoding] = accept_encoding_header
      end

      if bearer_token_request?
        headers[:accept]        = '*/*'
        headers[:authorization] = bearer_token_credentials_auth_header
      else
        headers[:authorization] = auth_header
      end
      headers
    end

  private

    def auth_header
      if @client.user_token?
        oauth_auth_header.to_s
      elsif @client.respond_to?(:bearer_token?)
        @client.bearer_token = @client.token unless @client.bearer_token?
        bearer_auth_header
      end
    end

    # @return [String]
    def bearer_auth_header
      "Bearer #{@client.bearer_token}"
    end

    # Generates authentication header for a bearer token request
    #
    # @return [String]
    def bearer_token_credentials_auth_header
      "Basic #{Base64.strict_encode64("#{@client.consumer_key}:#{@client.consumer_secret}")}"
    end

    def accept_encoding_header
      "deflate, gzip"
    end

    # @return [Hash]
    def credentials
      {
        consumer_key: @client.consumer_key,
        consumer_secret: @client.consumer_secret,
        token: @client.access_token,
        token_secret: @client.access_token_secret,
        ignore_extra_keys: true,
      }
    end
  end
end

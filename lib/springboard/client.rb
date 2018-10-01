require 'rubygems'
require 'faraday'
require 'json'
require 'logger'

require 'springboard/client/errors'

##
# Springboard namespace
module Springboard
  ##
  # The main point of interaction for the Springboard Client library.
  #
  # Client code must successfully authenticate with the API via the {#auth}
  # method before calling any HTTP methods or the API will return authorization
  # errors.
  #
  # Provides direct access to the URI-oriented interface via the HTTP methods.
  # Provides access to the URI-oriented interface via the {#[]} method.
  class Client
    ##
    # Default number of records per page when iterating over collection resources
    DEFAULT_PER_PAGE = 20

    ##
    # Default request timeout in seconds
    DEFAULT_TIMEOUT = 60

    ##
    # Default connection timeout in seconds
    DEFAULT_CONNECT_TIMEOUT = 10

    ##
    # @return [URI] The client's base URI
    attr_reader :base_uri

    ##
    # @return [Faraday::Connection] Faraday's connection
    attr_reader :connection

    ##
    # @param [String] base_uri Base URI
    # @option opts [Boolean, String] :debug Pass true to debug to stdout. Pass a String to debug to given filename.
    # @option opts [Boolean] :insecure Disable SSL certificate verification
    # @option opts [String] :token Springboard API Token
    def initialize(base_uri, opts={})
      @base_uri = URI.parse(base_uri)
      @opts = opts
      configure_connection!
    end

    ##
    # Set to true to enable debugging to STDOUT or a string to write to the file
    # at that path.
    #
    # @param [String, Boolean] debug
    #
    # @return [String, Boolean] The debug argument
    def debug=(debug)
      @opts[:debug] = debug
      configure_connection!
    end

    ##
    # @deprecated see {#initialize}.
    # Passes the given credentials to the server, storing the session token on success.
    #
    # @raise [AuthFailed] If the credentials were invalid or the server returned an error
    #
    # @return [true]
    #
    # @option opts [String] :username Springboard username
    # @option opts [String] :password Springboard password
    def auth(opts={})
      warn "[DEPRECATION] `auth` is deprecated. Please use `Springboard::Client.new '#{base_uri}', token: 'secret_token'` instead."

      unless opts[:username] && opts[:password]
        raise "Must specify :username and :password"
      end
      body = ::URI.encode_www_form \
        :auth_key => opts[:username],
        :password => opts[:password]
      response = post '/auth/identity/callback', body,
        'Content-Type' => 'application/x-www-form-urlencoded'

      if response.success?
        @session_cookie = response.headers['set-cookie']

        true
      else
        raise AuthFailed, "Springboard auth failed"
      end
    end

    ##
    # Performs a HEAD request against the given URI and returns the {Response}.
    #
    # @return [Response]
    def head(uri, headers=false); make_request(:head, uri, headers); end

    ##
    # Performs a HEAD request against the given URI. Returns the {Response}
    # on success and raises a {RequestFailed} on failure.
    #
    # @raise [RequestFailed] On error response
    #
    # @return [Response]
    def head!(uri, headers=false); raise_on_fail head(uri, headers); end

    ##
    # Performs a GET request against the given URI and returns the {Response}.
    #
    # @return [Response]
    def get(uri, headers=false); make_request(:get, uri, headers); end

    ##
    # Performs a GET request against the given URI. Returns the {Response}
    # on success and raises a {RequestFailed} on failure.
    #
    # @raise [RequestFailed] On error response
    #
    # @return [Response]
    def get!(uri, headers=false); raise_on_fail get(uri, headers); end

    ##
    # Performs a DELETE request against the given URI and returns the {Response}.
    #
    # @return [Response]
    def delete(uri, headers=false); make_request(:delete, uri, headers); end

    ##
    # Performs a DELETE request against the given URI. Returns the {Response}
    # on success and raises a {RequestFailed} on failure.
    #
    # @raise [RequestFailed] On error response
    #
    # @return [Response]
    def delete!(uri, headers=false); raise_on_fail delete(uri, headers); end

    ##
    # Performs a PUT request against the given URI and returns the {Response}.
    #
    # @return [Response]
    def put(uri, body, headers=false); make_request(:put, uri, headers, body); end

    ##
    # Performs a PUT request against the given URI. Returns the {Response}
    # on success and raises a {RequestFailed} on failure.
    #
    # @raise [RequestFailed] On error response
    #
    # @return [Response]
    def put!(uri, body, headers=false); raise_on_fail put(uri, body, headers); end

    ##
    # Performs a POST request against the given URI and returns the {Response}.
    #
    # @return [Response]
    def post(uri, body, headers=false); make_request(:post, uri, headers, body); end

    ##
    # Performs a POST request against the given URI. Returns the {Response}
    # on success and raises a {RequestFailed} on failure.
    #
    # @raise [RequestFailed] On error response
    #
    # @return [Response]
    def post!(uri, body, headers=false); raise_on_fail post(uri, body, headers); end

    ##
    # Returns a Resource for the given URI path.
    #
    # @return [Resource]
    def [](uri)
      Resource.new(self, uri)
    end

    ##
    # Iterates over each page of subordinate resources of the given collection
    # resource URI and yields the {Response} to the block.
    def each_page(uri)
      uri = URI.parse(uri)
      total_pages = nil
      page = 1
      uri.query_values = {'per_page' => DEFAULT_PER_PAGE}.merge(uri.query_values || {})
      while total_pages.nil? or page <= total_pages
        uri.merge_query_values! 'page' => page
        response = get!(uri)
        yield response
        total_pages ||= response['pages']
        page += 1
      end
    end

    ##
    # Iterates over each subordinate resource of the given collection resource
    # URI and yields its representation to the given block.
    def each(uri)
      each_page(uri) do |page|
        page['results'].each do |result|
          yield result
        end
      end
    end

    ##
    # Returns a count of subordinate resources of the given collection resource
    # URI.
    #
    # @param [#to_s] uri
    # @raise [RequestFailed] If the GET fails
    # @return [Integer] The subordinate resource count
    def count(uri)
      uri = URI.parse(uri)
      uri.merge_query_values! 'page' => 1, 'per_page' => 1
      get!(uri)['total']
    end

    private

    attr_reader :opts, :session_cookie

    def prepare_request_body(body)
      body.is_a?(Hash) ? JSON.dump(body) : body
    end

    def make_request(method, uri, headers=false, body=false)
      response = connection.__send__(method) do |request|
        request.url prepare_uri(uri).to_s

        request.headers = headers unless headers === false
        request.headers['Cookie'] = session_cookie if session_cookie

        request.body = prepare_request_body(body) unless body === false
      end

      new_response(response)
    end

    def raise_on_fail(response)
      if !response.success?
        error = RequestFailed.new "Request failed with status: #{response.status}"
        error.response = response
        raise error
      end
      response
    end

    def prepare_uri(uri)
      uri = URI.parse(uri)
      uri.to_s
        .gsub(/^#{base_uri.to_s}|^#{base_uri.path}/, '')
        .gsub(/^\//, '')
    end

    def new_response(faraday_response)
      Response.new faraday_response, self
    end

    def configure_connection!
      @connection = Faraday.new

      connection.url_prefix= base_uri.to_s

      connection.headers['Content-Type'] = 'application/json'
      connection.headers['Authorization'] = "Bearer #{opts[:token]}" if opts[:token]

      connection.ssl[:verify] = false if opts.has_key?(:insecure)

      connection.options.timeout  = DEFAULT_TIMEOUT
      connection.options.open_timeout = DEFAULT_CONNECT_TIMEOUT

      if debug = opts[:debug]
        connection.response :logger, debug_logger(debug), bodies: true
      end
    end

    def debug_logger(debug)
      Logger.new(debug == true ? STDOUT : debug)
    end
  end
end

require 'springboard/client/resource'
require 'springboard/client/response'
require 'springboard/client/body'
require 'springboard/client/uri'

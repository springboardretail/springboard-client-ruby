require 'rubygems'
require 'patron'
require 'addressable/uri'
require 'json'

require 'sagamore/client/errors'

module Sagamore
  class Client
    URI = Addressable::URI

    attr_reader :session, :base_uri

    ##
    # Initialize a Sagamore Client
    #
    # @param [String] base_uri Base URI
    # @option opts [true, String] :debug Pass true to debug to stdout. Pass a String to debug to given filename.
    # @option opts [Boolean] :insecure Disable SSL certificate verification
    def initialize(base_uri, opts={})
      @base_uri = URI.parse(base_uri)
      configure_session(base_uri, opts)
    end

    ##
    # Returns the underlying Patron::Session
    def session
      @session ||= Patron::Session.new
    end

    ##
    # Set to true to enable debugging to STDOUT or a string to write to the file
    # at that path.
    def debug=(debug)
      session.enable_debug(debug == true ? nil : debug)
    end

    ##
    # Passes the given credentials to the server. Stores the session token on
    # success and raises an AuthFailed on failure.
    def auth(opts={})
      unless opts[:username] && opts[:password]
        raise "Must specify :username and :password"
      end
      body = URI.form_encode \
        :auth_key => opts[:username],
        :password => opts[:password]
      response = post '/auth/identity/callback', body,
        'Content-Type' => 'application/x-www-form-urlencoded'
      response.success? or raise AuthFailed, "Sagamore auth failed"
    end

    ##
    # Performs a HEAD request against the given URI and returns the Response.
    def head(uri, headers=false); make_request(:head, uri, headers); end

    ##
    # Performs a HEAD request against the given URI. Returns the Response
    # on success and raises a RequestFailed on failure.
    def head!(uri, headers=false); raise_on_fail head(uri, headers); end

    ##
    # Performs a GET request against the given URI and returns the Response.
    def get(uri, headers=false); make_request(:get, uri, headers); end

    ##
    # Performs a GET request against the given URI. Returns the Response
    # on success and raises a RequestFailed on failure.
    def get!(uri, headers=false); raise_on_fail get(uri, headers); end

    ##
    # Performs a DELETE request against the given URI and returns the Response.
    def delete(uri, headers=false); make_request(:delete, uri, headers); end

    ##
    # Performs a DELETE request against the given URI. Returns the Response
    # on success and raises a RequestFailed on failure.
    def delete!(uri, headers=false); raise_on_fail delete(uri, headers); end

    ##
    # Performs a PUT request against the given URI and returns the Response.
    def put(uri, body, headers=false); make_request(:put, uri, headers, body); end

    ##
    # Performs a PUT request against the given URI. Returns the Response
    # on success and raises a RequestFailed on failure.
    def put!(uri, body, headers=false); raise_on_fail put(uri, body, headers); end

    ##
    # Performs a POST request against the given URI and returns the Response.
    def post(uri, body, headers=false); make_request(:post, uri, headers, body); end

    ##
    # Performs a POST request against the given URI. Returns the Response
    # on success and raises a RequestFailed on failure.
    def post!(uri, body, headers=false); raise_on_fail post(uri, body, headers); end

    ##
    # Returns a Resource for the given URI path.
    def [](uri)
      Resource.new(self, uri)
    end

    def each_page(uri)
      uri = URI.parse(uri)
      total_pages = nil
      page = 1
      uri.query_values = {'per_page' => 20}.merge(uri.query_values || {})
      while total_pages.nil? or page <= total_pages
        uri.merge_query_values! 'page' => page
        response = get!(uri)
        yield response
        total_pages ||= response['pages']
        page += 1
      end
    end

    def each(uri)
      each_page(uri) do |page|
        page['results'].each do |result|
          yield result
        end
      end
    end

    def count(uri)
      uri = URI.parse(uri)
      uri.merge_query_values! 'page' => 1, 'per_page' => 1
      get!(uri)['total']
    end

    private

    def prepare_request_body(body)
      body.is_a?(Hash) ? JSON.dump(body) : body
    end

    def make_request(method, uri, headers=false, body=false)
      args = [prepare_uri(uri).to_s]
      args.push prepare_request_body(body) unless body === false
      args.push headers unless headers === false
      new_response session.__send__(method, *args)
    end

    def raise_on_fail(response)
      if !response.success?
        error = RequestFailed.new "Request failed with status: #{response.status_line}"
        error.response = response
        raise error
      end
      response
    end

    def prepare_uri(uri)
      uri = URI.parse(uri)
      uri.path = uri.path.gsub(/^#{base_uri.path}/, '')
      uri
    end

    def new_response(patron_response)
      Response.new patron_response, self
    end

    def configure_session(base_url, opts)
      session.base_url = base_url
      session.headers['Content-Type'] = 'application/json'
      session.handle_cookies
      session.insecure = opts[:insecure] if opts.has_key?(:insecure)
      self.debug = opts[:debug] if opts.has_key?(:debug)
    end
  end
end

require 'sagamore/client/resource'
require 'sagamore/client/response'
require 'sagamore/client/body'
require 'sagamore/client/uri_ext'

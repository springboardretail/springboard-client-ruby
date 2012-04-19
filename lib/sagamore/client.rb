require 'rubygems'
require 'patron'
require 'addressable/uri'
require 'json'

module Sagamore
  class Client
    HTTP_METHODS = Patron::Request::VALID_ACTIONS
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

    def session
      @session ||= Patron::Session.new
    end

    def debug=(debug)
      session.enable_debug(debug == true ? nil : debug)
    end

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

    def get(uri, headers = {})
      make_request :get, uri, headers
    end

    def head(uri, headers = {})
      make_request :head, uri, headers
    end

    def delete(uri, headers = {})
      make_request :delete, uri, headers
    end

    def post(uri, body, headers = {})
      make_request :post, uri, headers, body
    end

    def put(uri, body, headers = {})
      make_request :put, uri, headers, body
    end

    %w{get head post put delete}.each do |http_method|
      define_method("#{http_method}!") do |*args, &block|
        response = __send__(http_method, *args, &block)
        if !response.success?
          raise RequestFailed, "Request failed with status: #{response.status_line}"
        end
        response
      end
    end

    def parse_request_body(body)
      body.is_a?(Hash) ? JSON.dump(body) : body
    end

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

    class RequestFailed < RuntimeError; end
    class AuthFailed < RequestFailed; end

    protected

    def make_request(method, uri, headers, body=false)
      args = [prepare_uri(uri).to_s]
      args.push parse_request_body(body) unless body === false
      args.push headers
      new_response session.__send__(method, *args)
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

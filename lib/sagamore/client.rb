require 'rubygems'
require 'patron'
require 'addressable/uri'
require 'json'

module Sagamore
  class Client
    HTTP_METHODS = Patron::Request::VALID_ACTIONS
    URI = Addressable::URI

    attr_reader :session

    def initialize(base_uri, opts={})
      configure_session(base_uri, opts)
    end

    def session
      @session ||= Patron::Session.new
    end

    def auth(opts={})
      unless opts[:username] && opts[:password]
        raise "Must specify :username and :password"
      end
      body = URI.form_encode \
        :auth_key => opts[:username],
        :password => opts[:password]
      post '/auth/identity/callback', body
    end

    def get(uri, headers = {})
      Response.new @session.get(uri, headers)
    end

    def head(uri, headers = {})
      Response.new @session.head(uri, headers)
    end

    def post(uri, data, headers = {})
      Response.new @session.post(uri, parse_request_body(data), headers)
    end

    def put(uri, data, headers = {})
      Response.new @session.put(uri, parse_request_body(data), headers)
    end

    def delete(uri, headers = {})
      Response.new @session.delete(uri, headers)
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

    protected

    def configure_session(base_url, opts)
      session.base_url = base_url
      session.handle_cookies
      if debug = opts[:debug]
        session.enable_debug(debug == true ? nil : debug)
      end
    end
  end
end

require 'sagamore/client/resource'
require 'sagamore/client/response'
require 'sagamore/client/uri_ext'

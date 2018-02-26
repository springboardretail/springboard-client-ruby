require 'uri'

module Springboard
  class Client
    ##
    # A wrapper around URI
    module URIHelpers
      ##
      # Returns a new URI object with the given Hash of query string parameters
      # merged into the existing query string parameters (if any).
      #
      # @return [URI]
      def self.merge_query_params(uri, params)
        new_uri = uri.dup
        params = query_to_hash(uri).merge(stringify_keys(params))
        new_uri.query = URI.encode_www_form(params)
        new_uri
      end

      ##
      # Returns a new URI object with the existing Hash of query string
      # parameters merged into the given Hash. The given hash is treated alias_method
      # default params.
      #
      # @return [URI]
      def self.reverse_merge_query_params(uri, default_params)
        new_uri = uri.dup
        params = stringify_keys(default_params).merge(query_to_hash(uri))
        new_uri.query = URI.encode_www_form(params)
        new_uri
      end

      ##
      # Returns a Hash of the query string parameters in the URI. If the URI
      # has no query string parameters, returns an empty Hash.
      #
      # @return [Hash]
      def self.query_to_hash(uri)
        uri.query ? CGI.parse(uri.query) : {}
      end

      private

      def self.stringify_keys(hash)
        hash.each_with_object({}) do |(key, value), hash|
          hash[key.to_s] = value.is_a?(Hash) ? stringify_keys(value) : value
        end
      end
    end
  end
end

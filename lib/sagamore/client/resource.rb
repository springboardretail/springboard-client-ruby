require 'sagamore/client/collection'

module Sagamore
  class Client
    class Resource
      ##
      # The resource's URI.
      #
      # @return [Addressable::URI]
      attr_reader :uri
      
      ##
      # The underlying Sagamore Client.
      #
      # @return [Client]
      attr_reader :client

      ##
      # @param [Sagamore::Client] client
      # @param [Addressable::URI, #to_s] uri
      def initialize(client, uri)
        @client = client
        @uri = URI.join('/', uri.to_s)
      end

      ##
      # Performs a HEAD request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def head(headers=false); call_client(:head, headers); end

      ##
      # Performs a HEAD request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure.
      #
      # @raise [RequestFailed] On error response
      #
      # @return [Response]
      def head!(headers=false); call_client(:head!, headers); end

      ##
      # Performs a GET request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def get(headers=false); call_client(:get, headers); end

      ##
      # Performs a GET request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure.
      #
      # @raise [RequestFailed] On error response
      #
      # @return [Response]
      def get!(headers=false); call_client(:get!, headers); end

      ##
      # Performs a DELETE request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def delete(headers=false); call_client(:delete, headers); end

      ##
      # Performs a DELETE request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure.
      #
      # @raise [RequestFailed] On error response
      #
      # @return [Response]
      def delete!(headers=false); call_client(:delete!, headers); end

      ##
      # Performs a PUT request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def put(body, headers=false); call_client(:put, body, headers); end

      ##
      # Performs a PUT request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure.
      #
      # @raise [RequestFailed] On error response
      #
      # @return [Response]
      def put!(body, headers=false); call_client(:put!, body, headers); end

      ##
      # Performs a POST request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def post(body, headers=false); call_client(:post, body, headers); end

      ##
      # Performs a POST request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure.
      #
      # @raise [RequestFailed] On error response
      #
      # @return [Response]
      def post!(body, headers=false); call_client(:post!, body, headers); end

      ##
      # Returns a new subordinate resource with the given sub-path.
      #
      # @return [Resource]
      def [](uri)
        clone(self.uri.subpath(uri))
      end

      ##
      # If query is given, returns a new resource where the given query hash
      # is merged with the existing query string parameters.
      #
      # If called with no arguments, returns the resources current query string
      # values as a hash.
      #
      # @return [Resource]
      def query(query=nil)
        if query
          uri = self.uri.dup
          uri.merge_query_values!(query)
          clone(uri)
        else
          self.uri.query_values || {}
        end
      end

      ##
      # Returns a cloned copy of the resource with the same URI.
      #
      # @return [Resource]
      def clone(uri=nil)
        self.class.new(client, uri ? uri : self.uri)
      end

      ##
      # Returns a new resource with the given embeds added to the query string
      # (via _include params).
      #
      # @return [Resource]
      def embed(*embeds)
        embeds = (query['_include'] || []) + embeds
        query('_include' => embeds)
      end

      ##
      # Returns true if a HEAD request to the resource returns a successful response,
      # false if it returns 404, otherwise raises an exception.
      #
      # @raise [RequestFailed] If response is not success or 404
      #
      # @return [Boolean]
      def exists?
        response = head
        return true if response.success?
        return false if response.status == 404
        error = RequestFailed.new "Request during call to 'exists?' resulted in non-404 error."
        error.response = response
        raise error
      end

      include Collection

      private

      ##
      # Calls a client method, passing the URI as the first argument.
      def call_client(method, *args, &block)
        client.__send__(method, *args.unshift(uri), &block)
      end
    end
  end
end

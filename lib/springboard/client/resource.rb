require 'springboard/client/collection'

module Springboard
  class Client
    ##
    # An representation of an API resource identified by a URI. Allows
    # triggering API calls via HTTP methods. Allows constructing new resources
    # in a chained style by calling the methods that manipulate the URI and
    # return a new resource.
    #
    # @example Chaining
    #   new_resource = resource.
    #     filter(:field => 'value').
    #     sort(:id).
    #     embed(:related_resource)
    #
    # Resources are usually constructed via the Client#[] method.
    class Resource
      ##
      # The resource's URI.
      #
      # @return [URI]
      attr_reader :uri

      ##
      # The underlying Springboard Client.
      #
      # @return [Client]
      attr_reader :client

      ##
      # @param [Springboard::Client] client
      # @param [URI, #to_s] uri
      def initialize(client, uri)
        @client = client
        @uri = URI.join(client.base_uri, client.base_uri.path + '/', uri)
      end

      ##
      # Performs a HEAD request against the resource's URI and returns the Response.
      #
      # @return [Response]
      def head(headers=false); call_client(:head, headers); end

      ##
      # Performs a HEAD request against the resource's URI. Returns the Response
      # on success and raises a RequestFailed on failure..
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
      def [](subpath)
        clone(URI.join(uri, uri.path + '/', subpath))
      end

      ##
      # If called with +params+ as a +Hash+:
      #
      # Returns a new resource where the given query hash
      # is merged with the existing query string parameters.
      #
      # If called with no arguments:
      #
      # Returns the resource's current query string parameters and values
      # as a hash.
      #
      # @return [Resource, Hash]

      ##
      # @overload query(params)
      #   Returns a new resource where the given +params+ hash of parameter
      #   names and values is merged with the existing query string parameters.
      #
      #   @param [Hash] params New query string parameters
      #   @return [Resource]
      #
      # @overload query()
      #   Returns the resource's current query string parameters and values
      #   as a hash.
      #
      #   @return [Hash]
      def query(params=nil)
        if params
          clone(URIHelpers.merge_query_params(uri, params))
        else
          URIHelpers.query_to_hash(uri)
        end
      end

      alias params query

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

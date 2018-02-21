require 'addressable/uri'

module Springboard
  class Client
    ##
    # A wrapper around Addressable::URI
    class URI
      ##
      # Returns a URI object based on the parsed string.
      #
      # @return [URI]
      def self.parse(value)
        return value if value.is_a?(self)
        new(::Addressable::URI.parse(value))
      end

      ##
      # Joins several URIs together.
      #
      # @return [URI]
      def self.join(*args)
        new(::Addressable::URI.join(*args))
      end

      ##
      # Creates a new URI object from an Addressable::URI
      #
      # @return [URI]
      def initialize(uri)
        @uri = uri
      end

      ##
      # Returns a new URI with the given subpath appended to it. Ensures a single
      # forward slash between the URI's path and the given subpath.
      #
      # @return [URI]
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        uri.join subpath.to_s.gsub(/^\//, '')
      end

      ##
      # Merges the given hash of query string parameters and values with the URI's
      # existing query string parameters (if any).
      def merge_query_values!(values)
        self.springboard_query_values = (self.query_values || {}).merge(normalize_query_hash(values))
      end

      def ==(other_uri)
        return false unless other_uri.is_a?(self.class)
        uri == other_uri.__send__(:uri)
      end

      private

      attr_reader :uri

      def springboard_query_values=(values)
        retval = self.query_values = normalize_query_hash(values)
        # Hack to strip digits from Addressable::URI's subscript notation
        self.query = self.query.gsub(/\[\d+\]=/, '[]=')
        retval
      end

      def self.delegate_and_wrap(*methods)
        methods.each do |method|
          define_method(method) do |*args, &block|
            result = @uri.__send__(method, *args, &block)
            if result.is_a?(Addressable::URI)
              self.class.new(result)
            else
              result
            end
          end
        end
      end

      delegate_and_wrap(
        :join, :path, :path=, :form_encode, :to_s,
        :query_values, :query_values=, :query, :query=
      )

      def normalize_query_hash(hash)
        hash.inject({}) do |copy, (k, v)|
          copy[k.to_s] = case v
            when Hash then normalize_query_hash(v)
            when true, false then v.to_s
            else v end
          copy
        end
      end
    end
  end
end

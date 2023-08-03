require 'uri'

module HeartlandRetail
  class Client
    ##
    # A wrapper around URI
    class URI
      ##
      # Returns a URI object based on the parsed string.
      #
      # @return [URI]
      def self.parse(value)
        return value.dup if value.is_a?(self)
        new(::URI.parse(value.to_s))
      end

      ##
      # Creates a new URI object from an Addressable::URI
      #
      # @return [URI]
      def initialize(uri)
        @uri = uri
      end

      ##
      # Clones the URI object
      #
      # @return [URI]
      def dup
        self.class.new(@uri.dup)
      end

      ##
      # Returns a new URI with the given subpath appended to it. Ensures a single
      # forward slash between the URI's path and the given subpath.
      #
      # @return [URI]
      def subpath(subpath)
        uri = dup
        uri.path = "#{path}/" unless path.end_with?('/')
        escaped_subpath = ::URI::Parser.new.escape(subpath.to_s.gsub(/^\//, ''))
        uri.path = uri.path + escaped_subpath
        uri
      end

      ##
      # Merges the given hash of query string parameters and values with the URI's
      # existing query string parameters (if any).
      def merge_query_values!(values)
        old_query_values = self.query_values || {}
        self.query_values = old_query_values.merge(normalize_query_hash(values))
      end

      ##
      # Checks if supplied URI matches current URI
      #
      # @return [boolean]
      def ==(other_uri)
        return false unless other_uri.is_a?(self.class)
        uri == other_uri.__send__(:uri)
      end

      ##
      # Overwrites the query using the supplied query values
      def query_values=(values)
        self.query = ::URI.encode_www_form(normalize_query_hash(values).sort)
      end

      ##
      # Returns a hash of query string parameters and values
      #
      # @return [hash]
      def query_values
        return nil if query.nil?
        ::URI.decode_www_form(query).each_with_object({}) do |(k, v), hash|
          if k.end_with?('[]')
            k.gsub!(/\[\]$/, '')
            hash[k] = Array(hash[k]) + [v]
          else
            hash[k] = v
          end
        end
      end

      private

      attr_reader :uri

      def self.delegate_and_wrap(*methods)
        methods.each do |method|
          define_method(method) do |*args, &block|
            @uri.__send__(method, *args, &block)
          end
        end
      end

      delegate_and_wrap(
        :path, :path=, :to_s, :query, :query=
      )

      def normalize_query_hash(hash)
        hash.inject({}) do |copy, (k, v)|
          k = "#{k}[]" if v.is_a?(Array) && !k.to_s.end_with?('[]')
          copy[k.to_s] = normalize_query_value(v)
          copy
        end
      end

      def normalize_query_value(value)
        case value
        when Hash then normalize_query_hash(value)
        when true, false then value.to_s
        when Array then value.uniq
        else value end
      end
    end
  end
end

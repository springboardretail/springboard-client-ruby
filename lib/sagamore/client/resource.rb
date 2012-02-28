module Sagamore
  class Client
    class Resource
      attr_accessor :uri

      CLIENT_DELEGATED_METHODS = HTTP_METHODS \
        + HTTP_METHODS.map{|m| "#{m}!".to_sym} \
        + [:each, :each_page]

      include ::Enumerable

      def initialize(client, uri)
        @client = client
        @uri = URI.join('/', uri.to_s)
      end

      def [](uri)
        self.class.new(@client, @uri.subpath(uri))
      end

      def query(query=nil)
        if query
          uri = @uri.dup
          uri.merge_query_values!(query)
          clone(uri)
        else
          @uri.query_values || {}
        end
      end

      def filter(new_filters)
        new_filters = JSON.parse(new_filters) if new_filters.is_a?(String)
        if filters = query['_filters']
          filters = JSON.parse(filters)
          filters = [filters] unless filters.is_a?(Array)
          filters.push(new_filters)
        else
          filters = new_filters
        end
        query('_filters' => filters.to_json)
      end

      def clone(uri=nil)
        self.class.new(@client, uri ? uri : @uri)
      end

      CLIENT_DELEGATED_METHODS.each do |method|
        define_method(method) do |*args, &block|
          @client.__send__(method, *args.unshift(@uri), &block)
        end
      end
    end
  end
end

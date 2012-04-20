module Sagamore
  class Client
    class Resource
      attr_reader :uri, :client

      CLIENT_DELEGATED_METHODS = HTTP_METHODS \
        + HTTP_METHODS.map{|m| "#{m}!".to_sym} \
        + [:each, :each_page, :count]

      include ::Enumerable

      def initialize(client, uri)
        @client = client
        @uri = URI.join('/', uri.to_s)
      end

      def [](uri)
        clone(self.uri.subpath(uri))
      end

      def query(query=nil)
        if query
          uri = self.uri.dup
          uri.merge_query_values!(query)
          clone(uri)
        else
          self.uri.query_values || {}
        end
      end

      def filter(new_filters)
        new_filters = JSON.parse(new_filters) if new_filters.is_a?(String)
        if filters = query['_filter']
          filters = JSON.parse(filters)
          filters = [filters] unless filters.is_a?(Array)
          filters.push(new_filters)
        else
          filters = new_filters
        end
        query('_filter' => filters.to_json)
      end

      def sort(*sorts)
        query('sort' => sorts)
      end

      def clone(uri=nil)
        self.class.new(client, uri ? uri : self.uri)
      end

      def first
        response = query(:per_page => 1, :page => 1).get!
        response[:results].first
      end

      def embed(*embeds)
        embeds = (query['_include'] || []) + embeds
        query('_include' => embeds)
      end

      CLIENT_DELEGATED_METHODS.each do |method|
        define_method(method) do |*args, &block|
          client.__send__(method, *args.unshift(uri), &block)
        end
      end
    end
  end
end

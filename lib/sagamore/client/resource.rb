module Sagamore
  class Client
    class Resource
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

      CLIENT_DELEGATED_METHODS.each do |method|
        define_method(method) do |*args, &block|
          @client.__send__(method, *args.unshift(@uri), &block)
        end
      end
    end
  end
end

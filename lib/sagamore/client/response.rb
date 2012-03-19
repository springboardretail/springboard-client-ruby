module Sagamore
  class Client
    class Response
      def initialize(response)
        @response = response
      end

      def [](key)
        data[key.to_s]
      end

      def data
        @data ||= JSON.parse(@response.body)
      end

      def success?
        @response.status < 400
      end

      def method_missing(method, *args, &block)
        @response.respond_to?(method) ? @response.__send__(method, *args, &block) : super
      end
    end
  end
end


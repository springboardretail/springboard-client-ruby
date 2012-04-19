module Sagamore
  class Client
    class Response
      def initialize(response, client)
        @response = response
        @client = client
      end

      def [](key)
        body[key]
      end

      def raw_body
        @response.body
      end

      def body
        @data ||= Body.new JSON.parse(@response.body)
      end

      def success?
        status < 400
      end

      def method_missing(method, *args, &block)
        @response.respond_to?(method) ? @response.__send__(method, *args, &block) : super
      end

      def resource
        if location = headers['Location']
          @client[headers['Location']]
        else
          nil
        end
      end
    end
  end
end


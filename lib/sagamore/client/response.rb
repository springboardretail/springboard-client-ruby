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
        @data ||= parse_body
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

      protected

      def parse_body
        if @response.body.empty?
          raise BodyError,
            "Response body is empty. (Hint: If you just created a new resource, try: response.resource.get)" 
        end

        begin
          data = JSON.parse(@response.body)
          Body.new data
        rescue JSON::ParserError => e
          raise BodyError, "Can't parse response body. (Hint: Try the raw_body method.)"
        end
      end
    end
  end
end


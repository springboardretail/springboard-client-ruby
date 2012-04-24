module Sagamore
  class Client
    class Response
      def initialize(response, client)
        @response = response
        @client = client
      end

      ##
      # Returns the corresponding key from "body".
      def [](key)
        body[key]
      end

      ##
      # Returns the raw response body as a String.
      def raw_body
        @response.body
      end

      ##
      # Returns the parsed response body as a Body object.
      #
      # Raises a BodyError if the body is not parseable.
      def body
        @data ||= parse_body
      end

      ##
      # Returns true if the request was successful, else false.
      def success?
        status < 400
      end

      def method_missing(method, *args, &block)
        @response.respond_to?(method) ? @response.__send__(method, *args, &block) : super
      end

      ##
      # If the response included a 'Location' header, returns a new Resource with
      # a URI set to its value, else nil.
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


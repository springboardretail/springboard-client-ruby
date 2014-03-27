module Springboard
  class Client
    ##
    # API request failure
    class RequestFailed < RuntimeError
      attr_accessor :response
    end

    ##
    # Authorization failure
    class AuthFailed < RequestFailed; end

    ##
    # Error parsing the response body
    class BodyError < RequestFailed; end
  end
end

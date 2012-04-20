module Sagamore
  class Client
    class RequestFailed < RuntimeError
      attr_accessor :response
    end

    class AuthFailed < RequestFailed; end

    class BodyError < RequestFailed; end
  end
end

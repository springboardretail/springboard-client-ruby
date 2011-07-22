require File.join(File.dirname(__FILE__), 'dynamic_error')

module Sagamore::RestClient
  class RestError < DynamicError; end
end

require File.join(File.dirname(__FILE__), 'dynamic_error')

module SlingshotRestClient  
  class RestError < DynamicError; end
end

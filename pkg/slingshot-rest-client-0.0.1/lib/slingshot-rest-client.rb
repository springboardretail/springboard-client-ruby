require 'rest_client'

# Include ActiveSupport before JSON to avoid to_json errors
require 'active_support'
require 'json'

require File.join(File.dirname(__FILE__), 'slingshot-rest-client', 'resource')
require File.join(File.dirname(__FILE__), 'slingshot-rest-client', 'dynamic_error')
require File.join(File.dirname(__FILE__), 'slingshot-rest-client', 'rest_error')
require File.join(File.dirname(__FILE__), 'slingshot-rest-client', 'hash_struct')

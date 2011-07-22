require 'rest_client'
require 'json'
require 'uri'

module Sagamore; end

require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'class')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'array')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'struct')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'hash')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'string')

require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'resource')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'dynamic_error')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'rest_error')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'enumerable_resource')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'deprecated')
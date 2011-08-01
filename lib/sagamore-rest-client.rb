require 'rest_client'
require 'json'
require 'cgi'

module Sagamore
  module RestClient
    def self.log=(log_file)
      ::RestClient.log = log_file
    end

    ##
    # Default query string parameters to pass when iterating over an enumerable collection.
    #
    # Useful for things like setting the default page size:
    #
    # @example
    #
    # Sagamore::RestClient.default_each_params = {:per_page => 100}
    def self.default_each_params=(params)
      @default_each_params = params
    end

    def self.default_each_params
      @default_each_params ||= {}
    end
  end
end

require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'class')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'array')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'struct')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'hash')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'core_ext', 'string')

require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'resource')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'dynamic_error')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'rest_error')
require File.join(File.dirname(__FILE__), 'sagamore-rest-client', 'enumerable_resource')
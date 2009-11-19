RestClient.log = File.join(Rails.root, 'log', 'restclient.log')

# A thin wrapper around RestClient (http://rest-client.heroku.com/)
# that provides automatic serialization and deserialization
module SlingshotRestClient  
  class Resource < RestClient::Resource    
    def get(additional_headers={})
      process_response { super }
    end
    
    def post(payload, additional_headers={})
      payload, additional_headers = prepare_request(payload, additional_headers)
      process_response { super }
    end
    
    def put(payload, additional_headers={})
      payload, additional_headers = prepare_request(payload, additional_headers)
      process_response { super }
    end

    def delete(additional_headers={})
      process_response { super }
    end
        
    private
    
    def prepare_request(payload, additional_headers)
      # Assume JSON
      if payload.is_a? Hash and !additional_headers[:content_type]
        additional_headers[:content_type] = 'application/json'
        payload = payload.to_json
      end
      [payload, additional_headers]
    end
    
    def process_response(options={}, &block)
      response = yield
      RAILS_DEFAULT_LOGGER.debug "Response:"
      RAILS_DEFAULT_LOGGER.debug response.inspect
      # If 201 Created, GET the newly created resource
      if response.code == 201
        new_url = URI.parse(self.url)
        new_url.path = response.headers[:location]
        new_resource = self.class.new(new_url.to_s, self.options)
        RAILS_DEFAULT_LOGGER.debug "Following 201: #{new_url}"
        new_resource.get
      elsif response.headers[:content_type] == 'application/json'
        JSON.parse(response).to_struct(true)
      else
        response
      end
    rescue RestClient::Unauthorized => exception
      raise RestError.new("Unauthorized", :unauthorized, nil)
    rescue Errno::ECONNREFUSED
      raise RestError.new("Could not connect to server", 'connection_error')
    rescue RestClient::ExceptionWithResponse => exception
      Errors.raise_exception(exception)
    end
  end
  
  module Errors
    def self.raise_exception(exception)
      raise translate_exception(exception)
    end
    
    def self.translate_exception(exception)
      error_details = parse_error_body(exception)
      error_type = error_details['error'].underscore.to_sym
      error_message = error_details['message']

      RestError.new(error_message, error_type, error_details['details'])
    end
    
    def self.parse_error_body(exception)
      begin
        JSON.parse(exception.response.body)
      rescue
        raise exception
      end
    end
  end
end

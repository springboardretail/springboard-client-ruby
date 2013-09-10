# A thin wrapper around RestClient (http://rest-client.heroku.com/)
# that provides automatic serialization and deserialization
module Sagamore::RestClient
  class Resource < ::RestClient::Resource
    def get(additional_headers={})
      additional_headers = set_session_cookie(additional_headers)
      process_response { super }
    end
    
    def post(payload, additional_headers={})
      additional_headers = set_session_cookie(additional_headers)
      payload, additional_headers = prepare_request(payload, additional_headers)
      process_response { super }
    end
    
    def put(payload, additional_headers={})
      additional_headers = set_session_cookie(additional_headers)
      payload, additional_headers = prepare_request(payload, additional_headers)
      process_response { super }
    end

    def delete(additional_headers={})
      additional_headers = set_session_cookie(additional_headers)
      process_response { super }
    end
    
    ##
    # Returns a new resource with the values pased in the hash *appended* to the query string
    def query_string(hash)
      new_url = url =~ /\?/ ? "#{url}&" : "#{url}?"
      new_url += hash.map do |key, value|
        if value.is_a? Array
          value.map {|v| "#{key}[]=#{CGI.escape(v.to_s)}"}.join('&')
        else
          "#{key}=#{CGI.escape(value.to_s)}"
        end
      end.join('&')
      self.class.new(new_url, self.options)
    end

    def [](suburl, &new_block)
      r = super
      r.session_cookie = session_cookie
      r
    end

    def session_cookie
      @session_cookie ||= authenticate
    end

    def session_cookie=(cookie)
      @session_cookie = cookie
    end

    private

    def set_session_cookie(additional_headers)
      additional_headers[:cookies] ||= {}
      if session_cookie
        additional_headers[:cookies]["rack.session"] = CGI::escape session_cookie
      end
      additional_headers
    end

    def authenticate
      auth_resource = ::RestClient::Resource.new /(https?:\/\/[^\/]+)/.match(url)[0]
      response = auth_resource['api/auth/identity/callback'].
        post(:auth_key => user, :password => password)

      if response.headers[:location] && response.headers[:location] =~ /^\/api\/auth\/failure/
        raise ::Sagamore::RestClient::RestError.new("Authentication failed", :unauthorized, nil)
      else
        response.cookies['rack.session']
      end
    rescue RestClient::BadRequest
      raise ::Sagamore::RestClient::RestError.new("Authentication failed", :unauthorized, nil)
    end

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
      # If 201 Created, GET the newly created resource
      if response.code == 201
        new_url = URI.parse(self.url)
        new_url.path = response.headers[:location]
        resource = self.class.new(new_url.to_s, self.options)
        resource.session_cookie = session_cookie
        resource
      elsif response.headers[:content_type] =~ /^application\/.*[+]?json/
        JSON.parse(response).to_struct(true)
      else
        response
      end
    rescue ::RestClient::Unauthorized => exception
      raise ::Sagamore::RestClient::RestError.new("Unauthorized", :unauthorized, nil)
    rescue Errno::ECONNREFUSED
      raise ::Sagamore::RestClient::RestError.new("Could not connect to server", 'connection_error')
    rescue ::RestClient::ExceptionWithResponse => exception
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

      ::Sagamore::RestClient::RestError.new(error_message, error_type, error_details['details'])
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

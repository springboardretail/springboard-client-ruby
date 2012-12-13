require 'sagamore-client'
require 'webmock/rspec'
require 'shared_client_context'

class String
  def to_uri
    Addressable::URI.parse(self)
  end
end

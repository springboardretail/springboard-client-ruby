require 'sagamore-client'
require 'webmock/rspec'

class String
  def to_uri
    Addressable::URI.parse(self)
  end
end

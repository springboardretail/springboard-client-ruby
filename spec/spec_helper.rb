require 'coveralls'
Coveralls.wear!

require 'springboard-retail'
require 'webmock/rspec'
require 'shared_client_context'

class String
  def to_uri
    Addressable::URI.parse(self)
  end
end

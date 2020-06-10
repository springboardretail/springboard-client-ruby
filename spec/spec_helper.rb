require 'coveralls'
Coveralls.wear!

require 'heartland-retail'
require 'webmock/rspec'
require 'shared_client_context'

RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end

class String
  def to_uri
    HeartlandRetail::Client::URI.parse(self)
  end
end

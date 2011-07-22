CLIENT = Sagamore::RestClient::Resource.new \
  'http://sagamore.local:8001',
  :user => 'admin',
  :password => 'admin'
  
def client
  CLIENT
end
  
puts "'client' method available for testing: #{client.inspect}"
# Sagamore Client

This is the Sagamore Client library for Ruby. It provides access to the Sagamore HTTP API.

It is a wrapper around the [Patron](http://toland.github.com/patron/) HTTP client library.

## Examples

### Connecting

```ruby
sagamore = Sagamore::Client.new 'http://example.sagamore.us/api',
sagamore.auth :username => 'user', :password => 'secret'
```

### Resource oriented

```ruby
resource = sagamore[:items][1234]
response = resource.get
```

### URI oriented

```ruby
response = sagamore.get '/items/1234'
```

### Collection Resources

Resources include Ruby's Enumerable module for easy iteration over collections:

```ruby
sagamore[:items].each do |item|
  puts item['description']
end

item_count = sagamore[:items].count

usernames = sagamore[:users].map {|user| user['login']}
```

Resources also provide a `filter` method that support's Sagamore's advanced filter syntax:

```ruby
active_users = sagamore[:users].filter(:active => true)
active_users.each {|user| # do something with each active user }

# filter returns a new resource which allows for chaining:
items = sagamore[:items]
active_items = items.filter(:active => true)
active_items.filter(:price => {'$gt' => 10}).each do |item|
   # ...
end
```

### Request body

If the request body is a Hash, it will automatically be serialized as JSON. Otherwise, it is
passed through untouched:

```ruby
# this:
sagamore[:some_collection].post :a => 1, :b => 2

# is equivalent to this:
sagamore[:some_collection].post '{"a":1,"b":2}'
```

### Response

```ruby
response = sagamore[:items][1].get

response.status # Response status code as an Integer
response.success? # true/false depending on whether 'status' indicates non-error
response.body # Raw response body as a string
response.data # Parsed response body as a Hash or Array
response[:some_key] # Returns the corresponding key from 'data'
response.headers # Response headers as a Hash
```

### Bang variants

All HTTP request methods have a bang variant that raises an exception on failure:

```ruby
response = sagamore[:i_dont_exist].get
response.status
# => 404

sagamore[:i_dont_exist].get!
# Raises Sagamore::Client::RequestFailed exception
```

### Filtering collections

```ruby
filtered_items = sagamore[:items] \
  .filter('custom@group' => 'somegroup') \
  .filter('price' => {'$gt' => 100})

filtered_items.each do |item|
  # ...do something with item
end
```

### Debugging

```ruby
# Log request/response trace to stdout
client.debug = true

# Or, log to a file
client.debug = '/path/to/file.log'

# Same values can be passed via :debug option to client constructor
client = Sagamore::Client.new '<url>', :debug => true
```

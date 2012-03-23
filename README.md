# Sagamore Client

This is the Sagamore Client library for Ruby. It provides access to the Sagamore HTTP API.

It is a wrapper around the [Patron](http://toland.github.com/patron/) HTTP client library.

## Connecting

```ruby
sagamore = Sagamore::Client.new 'http://example.sagamore.us/api',
sagamore.auth :username => 'user', :password => 'secret'
```

## Resource oriented

```ruby
resource = sagamore[:items][1234]
response = resource.get
response = resource.delete

# Query string generation:
resource1 = sagamore[:items]
resource2 = resource.query(:key1 => 'val1', 'key with spaces' => 'val with spaces')
resource2.uri.to_s
# => "/items?key%20with%20spaces=val%20with%20spaces&key1=val1"
```

## URI oriented

```ruby
response = sagamore.get '/items/1234'
response = sagamore.delete '/items/1234'
item_count = sagamore.count '/items'
```

## Collection Resources

### Enumerable
Resources include Ruby's Enumerable module for easy iteration over collections:

```ruby
sagamore[:items].each do |item|
  puts item['description']
end

item_count = sagamore[:items].count

usernames = sagamore[:users].map {|user| user['login']}
```

### Filtering
Resources have a `filter` method that support's Sagamore's advanced filter syntax:

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

### Sorting
Resources have a `sort` method that accepts any number of sort options. Note that each call to sort overwrites any previous sorts.

```ruby
resource.sort(:id, :price)
resource.sort('created_at,desc')

# returns a new resource for chaining:
resource.sort(:description, :created_at).filter(:active => true).each do |item|
  # ...
end
```

## Request body

If the request body is a Hash, it will automatically be serialized as JSON. Otherwise, it is
passed through untouched:

```ruby
# this:
sagamore[:some_collection].post :a => 1, :b => 2

# is equivalent to this:
sagamore[:some_collection].post '{"a":1,"b":2}'
```

## Response

```ruby
response = sagamore[:items][1].get

response.status # Response status code as an Integer
response.success? # true/false depending on whether 'status' indicates non-error
response.body # Raw response body as a string
response.data # Parsed response body as a Hash or Array
response[:some_key] # Returns the corresponding key from 'data'
response.headers # Response headers as a Hash
```

## Bang variants

All HTTP request methods have a bang variant that raises an exception on failure:

```ruby
response = sagamore[:i_dont_exist].get
response.status
# => 404

sagamore[:i_dont_exist].get!
# Raises Sagamore::Client::RequestFailed exception
```

## Debugging

```ruby
# Log request/response trace to stdout
client.debug = true

# Or, log to a file
client.debug = '/path/to/file.log'

# Same values can be passed via :debug option to client constructor
client = Sagamore::Client.new '<url>', :debug => true
```

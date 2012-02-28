# Sagamore Client

This is the Sagamore Client library for Ruby. It provides access to the Sagamore HTTP API.

It is a wrapper around the [Patron](http://toland.github.com/patron/) HTTP client library.

## Examples

### Connecting

```ruby
sagamore = Sagamore::Client.new 'http://example.sagamore.us',
  :username => 'user',
  :password => 'secret'
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

### Request body

If the request body is a Hash, it will automatically be serialized as JSON. Otherwise, it is
passed through untouched:

```ruby
# this:
sagamore[:some_collection].post :a => 1, :b => 2

# is equivalent to this:
sagamore[:some_collection].post '{"a":1,"b":2}'
```

### Bang variants

All HTTP request methods have a bang variant that raises an exception on failure:

```ruby
response = sagamore[:i_dont_exist].get
puts response.status
# 404

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

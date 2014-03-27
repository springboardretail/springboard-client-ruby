# Springboard Retail Client

[![Gem Version](https://badge.fury.io/rb/springboard-retail.png)](http://badge.fury.io/rb/springboard-retail)
[![Build Status](https://travis-ci.org/springboardretail/springboard-client-ruby.png?branch=master)](https://travis-ci.org/springboardretail/springboard-client-ruby)
[![Code Climate](https://codeclimate.com/github/springboardretail/springboard-client-ruby.png)](https://codeclimate.com/github/springboardretail/springboard-client-ruby)
[![Coverage Status](https://coveralls.io/repos/springboardretail/springboard-client-ruby/badge.png)](https://coveralls.io/r/springboardretail/springboard-client-ruby)
[![Dependency Status](https://gemnasium.com/springboardretail/springboard-client-ruby.png)](https://gemnasium.com/springboardretail/springboard-client-ruby)

This is the [Springboard Retail](http://springboardretail.com/) (a point-of-sale/retail management system) client library for Ruby. It provides access to the Springboard Retail HTTP API.

It is a wrapper around the [Patron](http://toland.github.com/patron/) HTTP client library. Supports MRI 1.9+.

You can find [documentation here](http://rdoc.info/github/springboard/springboard-client-ruby).

## Installation

You need a recent version of libcurl and a sane build environment.

Debian/Ubuntu:

```
sudo apt-get install build-essential libcurl4-openssl-dev
gem install springboard-retail
```

## Connecting

```ruby
springboard = Springboard::Client.new 'http://example.springboard.us/api'
springboard.auth :username => 'user', :password => 'secret'
```

## Resource oriented

```ruby
resource = springboard[:items][1234]
response = resource.get
response = resource.delete

# Query string generation:
resource1 = springboard[:items]
resource2 = resource.query(:key1 => 'val1', 'key with spaces' => 'val with spaces')
resource2.uri.to_s
# => "/items?key%20with%20spaces=val%20with%20spaces&key1=val1"
```

## URI oriented

```ruby
response = springboard.get '/items/1234'
response = springboard.delete '/items/1234'
item_count = springboard.count '/items'
```

## Collection Resources

### Enumerable
Resources include Ruby's Enumerable module for easy iteration over collections:

```ruby
springboard[:items].each do |item|
  puts item['description']
end

item_count = springboard[:items].count

usernames = springboard[:users].map {|user| user['login']}
```

### Filtering
Resources have a `filter` method that support's Springboard's advanced filter syntax:

```ruby
active_users = springboard[:users].filter(:active => true)
active_users.each do |user|
  # do something with each active user
end

# filter returns a new resource which allows for chaining:
items = springboard[:items]
active_items = items.filter(:active => true)
active_items.filter(:price => {'$gt' => 10}).each do |item|
   # ...
end

# filtering custom fields:
springboard[:items].filter('custom@size'=> 'XL')
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

### Creating Resources

Create a new resource via POST:

```ruby
collection = client[:items]
response = collection.post! :description => 'Some New Item'
response.status_line
# => "HTTP/1.1 201 Created"

# To fetch the newly created resource:
new_item_response = response.resource.get!
new_item_response[:description]
# => "Some New Item"
```

### Embedding Related Resources

Use the `embed` method to include the contents of related resource in the response body of each item in the collection:

```ruby
collection = client[:sales][:orders].embed(:customer, :location)
collection.first.to_hash
# => {
  "id" => 1,
  "customer_id" => 2,
  "customer" =>  {
    # customer data
  },
  "location_id" => 3,
  "location" =>  {
    # location data
  }
}
```

The `embed` method accepts one or more arguments as symbols or strings. It supports chaining and will merge the results of multiple calls.

### Looping while results exist

Issuing deletes while iterating over a collection resource can cause the pagination to shift resulting in unexpected behavior. Use `while_results` when you want to:

* Consume messages from a queue, deleting each message after it has been processed.
* Delete all resources in a collection that doesn't support a top-level DELETE method.

For example:

```ruby
collection = client[:system][:messages]
collection.while_results do |message|
  # process message here...
  collection[message['id']].delete!
end
```

## Request body

If the request body is a Hash, it will automatically be serialized as JSON. Otherwise, it is
passed through untouched:

```ruby
# this:
springboard[:some_collection].post :a => 1, :b => 2

# is equivalent to this:
springboard[:some_collection].post '{"a":1,"b":2}'
```

## Response

```ruby
response = springboard[:items][1].get

response.status # Response status code as an Integer
response.success? # true/false depending on whether 'status' indicates non-error
response.body # Returns a Springboard::Client::Body object (see below)
response.raw_body # Returns the raw response body as a string
response[:some_key] # Returns the corresponding key from 'body'
response.headers # Response headers as a Hash
response.resource # Returns a Resource if the response included a "Location" header, else nil
```

### Response Body

Given the following JSON response from the server:

```javascript
{
  "id": 1234,
  "custom": {
    "color": "Blue"
  }
}
```

Here are the various ways you can access the data:

```ruby
body = response.body

# Symbols and strings can be used interchangeably for keys
body[:id]
# => 1234

body[:custom][:color]
# => "Blue"

body['custom']['color']
# => "Blue"

body.to_hash
# => {"id"=>1234, "custom"=>{"color"=>"Blue"}}

response.raw_body
# => "{\"id\":1234,\"custom\":{\"color\":\"Blue\"}}"
```

## Bang variants

All HTTP request methods have a bang variant that raises an exception on failure:

```ruby
response = springboard[:i_dont_exist].get
response.status
# => 404

springboard[:i_dont_exist].get!
# Raises Springboard::Client::RequestFailed exception

# To access the response from the exception:
begin
  springboard[:i_dont_exist].get!
rescue Springboard::Client::RequestFailed => error
  puts error.response.status
end
# => 404

```

## Debugging

```ruby
# Log request/response trace to stdout
client.debug = true

# Or, log to a file
client.debug = '/path/to/file.log'

# Same values can be passed via :debug option to client constructor
client = Springboard::Client.new '<url>', :debug => true
```

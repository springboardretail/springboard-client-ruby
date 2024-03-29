# Heartland Retail API Client

[![Gem Version](https://badge.fury.io/rb/heartland-retail.svg)](https://badge.fury.io/rb/heartland-retail)
[![Build Status](https://github.com/springboardretail/springboard-client-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/springboardretail/springboard-client-ruby/actions/workflows/build.yml)
[![Code Climate](https://codeclimate.com/github/springboardretail/springboard-client-ruby.png)](https://codeclimate.com/github/springboardretail/springboard-client-ruby)
[![Coverage Status](https://coveralls.io/repos/github/springboardretail/springboard-client-ruby/badge.svg?branch=master)](https://coveralls.io/github/springboardretail/springboard-client-ruby?branch=master)

This is the [Heartland Retail](http://heartlandretail.us/) (a point-of-sale/retail management system) client library for Ruby. It provides access to the [Heartland Retail HTTP API](https://dev.retail.heartland.us/).

It is a wrapper around the [Faraday](https://github.com/lostisland/faraday) HTTP client library.

You can find [documentation here](https://rdoc.info/github/springboardretail/springboard-client-ruby).

## Installation

You need a recent version of libcurl and a sane build environment.

Debian/Ubuntu:

```bash
sudo apt-get install build-essential libcurl4-openssl-dev
gem install heartland-retail
```

## Connecting

```ruby
require 'heartland-retail'
heartland = HeartlandRetail::Client.new(
  'https://example.retail.heartland.us/api/',
  token: 'secret_token'
)
```

## Resource oriented

```ruby
resource = heartland[:items][1234]
response = resource.get
response = resource.delete

# Query string generation:
resource1 = heartland[:items]
resource2 = resource.query(:key1 => 'val1', 'key with spaces' => 'val with spaces')
resource2.uri.to_s
# => "/items?key%20with%20spaces=val%20with%20spaces&key1=val1"
```

## URI oriented

```ruby
response = heartland.get '/items/1234'
response = heartland.delete '/items/1234'
item_count = heartland.count '/items'
```

## Collection Resources

### Enumerable

Resources include Ruby's Enumerable module for easy iteration over collections:

```ruby
heartland[:items].each do |item|
  puts item['description']
end

item_count = heartland[:items].count

usernames = heartland[:users].map {|user| user['login']}
```

### Filtering

Resources have a `filter` method that support's Heartland Retail's advanced filter syntax:

```ruby
active_users = heartland[:users].filter(:active => true)
active_users.each do |user|
  # do something with each active user
end

# filter returns a new resource which allows for chaining:
items = heartland[:items]
active_items = items.filter(:active => true)
active_items.filter(:price => {'$gt' => 10}).each do |item|
   # ...
end

# filtering custom fields:
heartland[:items].filter('custom@size'=> 'XL')
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

### Returning select fields

Resources have a `only` method that accepts any number of field keys to return only the selected fields. Note that each call to `only` overwrites any previous fields.

```ruby
resource.only(:id)
resource.only(:public_id, :updated_at)

# returns a new resource for chaining:
resource.only(:public_id, :updated_at).filter(:active => true).each do |item|
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

- Consume messages from a queue, deleting each message after it has been processed.
- Delete all resources in a collection that doesn't support a top-level DELETE method.

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
heartland[:some_collection].post :a => 1, :b => 2

# is equivalent to this:
heartland[:some_collection].post '{"a":1,"b":2}'
```

## Response

```ruby
response = heartland[:items][1].get

response.status # Response status code as an Integer
response.success? # true/false depending on whether 'status' indicates non-error
response.body # Returns a HeartlandRetail::Client::Body object (see below)
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
response = heartland[:i_dont_exist].get
response.status
# => 404

heartland[:i_dont_exist].get!
# Raises HeartlandRetail::Client::RequestFailed exception

# To access the response from the exception:
begin
  heartland[:i_dont_exist].get!
rescue HeartlandRetail::Client::RequestFailed => error
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
client = HeartlandRetail::Client.new '<url>', :debug => true
```

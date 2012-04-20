require 'spec_helper'

describe Sagamore::Client::Resource do
  include_context "client"

  let(:resource_path) { '/some/path' }
  let(:resource) { Sagamore::Client::Resource.new(client, resource_path) }

  def parse_uri(uri)
    Addressable::URI.parse(uri)
  end

  describe "[]" do
    it "should return a new resource" do
      resource["subpath"].should be_a Sagamore::Client::Resource
      resource["subpath"].object_id.should_not == resource.object_id
    end
    
    it "should return a resource with the given subpath appended to its URI" do
      resource["subpath"].uri.to_s.should == "/some/path/subpath"
    end

    it "should return a resource with the same client instance" do
      resource["subpath"].client.should === resource.client
    end

    it "should accept a symbol as a path" do
      resource[:subpath].uri.to_s.should == "/some/path/subpath"
    end

    it "should accept a symbol as a path" do
      resource[:subpath].uri.to_s.should == "/some/path/subpath"
    end

    it "should not URI encode the given subpath" do
      resource["subpath with spaces"].uri.to_s.should == "/some/path/subpath with spaces"
    end
  end

  describe "query" do
    describe "when called with a hash" do
      it "should set the query string parameters" do
        resource.query(:a => 1, :b => 2).uri.to_s.should == "/some/path?a=1&b=2"
      end

      it "should URL encode the given keys and values" do
        resource.query("i have spaces" => "so do i: duh").uri.to_s.
          should == "/some/path?i%20have%20spaces=so%20do%20i%3A%20duh"
      end
    end
    
    describe "when called without arguments" do
      it "should return the current query string parameters as a hash" do
        resource.query.should == {}
        new_resource = resource.query :a => 1, :b => 2
        new_resource.query.should == {"a"=>"1", "b"=>"2"}
      end
    end
  end

  describe "filter" do
    describe "when given a hash" do
      it "should add a _filter query string param" do
        resource.filter(:a => 1, :b => 2).uri.should ==
          '/some/path?_filter={"a":1,"b":2}'.to_uri
      end
    end
    
    describe "when called multiple times" do
      it "should append args to _filter param as JSON array" do
        resource.filter(:a => 1).filter(:b => 2).filter(:c => 3).uri.should ==
          '/some/path?_filter=[{"a":1},{"b":2},{"c":3}]'.to_uri
      end
    end

    describe "when given a string" do
      it "should add a _filter query string param" do
        resource.filter('{"a":1,"b":2}').uri.should ==
          '/some/path?_filter={"a":1,"b":2}'.to_uri
      end
    end
  end

  describe "sort" do
    it "should set the sort parameter based on the given values" do
      resource.sort('f1', 'f2,desc').uri.query.should == 'sort[]=f1&sort[]=f2%2Cdesc'
    end

    it "should replace any existing sort parameter" do
      resource.sort('f1', 'f2,desc')
      resource.sort('f3,asc', 'f4').uri.query.should == 'sort[]=f3%2Casc&sort[]=f4'
    end
  end


  %w{count get put post delete each each_page}.each do |method|
    describe method do
      it "should call the client's #{method} method with the resource's URI" do
        client.should_receive(method).with(resource.uri)
        resource.__send__(method)
      end
    end
  end

  describe "first" do
    let(:response_data) {
      {
        :status => 200,
        :body => {:results => [{:id => "Me first!"}, {:id => "Me second!"}]}.to_json
      }
    }

    it "should set the per_page query string param to 1" do
      request_stub = stub_request(:get, "#{base_url}/some/path?page=1&per_page=1").to_return(response_data)
      resource.first
      request_stub.should have_been_requested
    end

    it "should return the first element of the :results array" do
      request_stub = stub_request(:get, "#{base_url}/some/path?page=1&per_page=1").to_return(response_data)
      resource.first.should == {"id" => "Me first!"}
    end
  end

  describe "embed" do
    it "should support a single embed" do
      resource.embed(:thing1).uri.to_s.should == 
        '/some/path?_include[]=thing1'
    end

    it "should support multiple embeds" do
      resource.embed(:thing1, :thing2, :thing3).uri.to_s.should == 
        '/some/path?_include[]=thing1&_include[]=thing2&_include[]=thing3'
    end

    it "should merge multiple embed calls" do
      resource.embed(:thing1, :thing2).embed(:thing3, :thing4).uri.to_s.should == 
        '/some/path?_include[]=thing1&_include[]=thing2&_include[]=thing3&_include[]=thing4'
    end

    it "should merge multiple embed calls" do
      resource.embed(:thing1, :thing2).embed(:thing3, :thing4).uri.to_s.should == 
        '/some/path?_include[]=thing1&_include[]=thing2&_include[]=thing3&_include[]=thing4'
    end

    it "should merge a call to embed with a manually added _include query param" do
      resource.query('_include[]' => :thing1).embed(:thing2, :thing3).uri.to_s.should == 
        '/some/path?_include[]=thing1&_include[]=thing2&_include[]=thing3'
    end
  end
end

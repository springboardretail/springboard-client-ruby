require 'spec_helper'

describe Springboard::Client::Resource do
  include_context "client"

  let(:resource_path) { '/some/path' }
  let(:resource) { Springboard::Client::Resource.new(client, resource_path) }

  def parse_uri(uri)
    Addressable::URI.parse(uri)
  end

  describe "[]" do
    it "should return a new resource" do
      resource["subpath"].should be_a Springboard::Client::Resource
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

  %w{query params}.each do |method|
    describe method do
      describe "when called with a hash" do
        it "should set the query string parameters" do
          resource.__send__(method, :a => 1, :b => 2).uri.to_s.should == "/some/path?a=1&b=2"
        end

        it "should URL encode the given keys and values" do
          resource.__send__(method, "i have spaces" => "so do i: duh").uri.to_s.
            should == "/some/path?i%20have%20spaces=so%20do%20i%3A%20duh"
        end

        it "should add bracket notation for array parameters" do
          resource.__send__(method, :somearray => [1, 2, 3]).uri.to_s.should == "/some/path?somearray[]=1&somearray[]=2&somearray[]=3"
        end
      end

      describe "when called without arguments" do
        it "should return the current query string parameters as a hash" do
          resource.__send__(method).should == {}
          new_resource = resource.__send__(method, :a => 1, :b => 2)
          new_resource.__send__(method).should == {"a"=>"1", "b"=>"2"}
        end
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

  %w{count each each_page}.each do |method|
    describe method do
      it "should call the client's #{method} method with the resource's URI" do
        client.should_receive(method).with(resource.uri)
        resource.__send__(method)
      end
    end
  end

  %w{get head delete}.each do |method|
    describe method do
      it "should call the client's #{method} method with the resource's URI and a header hash" do
        client.should_receive(method).with(resource.uri, false)
        resource.__send__(method)
      end
    end
  end

  %w{put post}.each do |method|
    describe method do
      it "should call the client's #{method} method with the resource's URI, the given body, and a headers hash" do
        client.should_receive(method).with(resource.uri, "body", false)
        resource.__send__(method, "body")
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

  describe "while_results" do
    it "should yield each result to the block as long as the response includes results" do
      results = ["r1", "r2", "r3"]

      request_stub = stub_request(:get, "#{base_url}/some/path").to_return do |req|
        {:body => {:results => results}.to_json}
      end

      yielded_results = []

      # timeout in case of endless loop
      Timeout::timeout(10) do
        resource.while_results do |result|
          yielded_results.push results.shift
        end
      end

      yielded_results.should == ["r1", "r2", "r3"]
    end

    it "should raise an exception if it receives an error response" do
      request_stub = stub_request(:get, "#{base_url}/some/path").to_return do |req|
        {:status => 400}
      end

      # timeout in case of endless loop
      Timeout::timeout(10) do
        expect do
          resource.while_results do |result|
            # nothing
          end
        end.to raise_error(Springboard::Client::RequestFailed)
      end
    end

    describe "exists?" do
      let(:response) { mock(Springboard::Client::Response) }

      it "should return true if the response indicates success" do
        response.stub!(:success?).and_return(true)
        client.should_receive(:head).with(resource.uri, false).and_return(response)
        resource.exists?.should === true
      end

      it "should return false if the response status is 404" do
        response.stub!(:status).and_return(404)
        response.stub!(:success?).and_return(false)
        client.should_receive(:head).with(resource.uri, false).and_return(response)
        resource.exists?.should === false
      end

      it "should raise a RequestFailed exception if the request fails but the status is not 404" do
        response.stub!(:status).and_return(400)
        response.stub!(:success?).and_return(false)
        client.should_receive(:head).with(resource.uri, false).and_return(response)
        expect { resource.exists? }.to raise_error { |e|
          e.should be_a Springboard::Client::RequestFailed
          e.response.should === response
          e.message.should == "Request during call to 'exists?' resulted in non-404 error."
        }
      end
    end

    describe "empty?" do
      it "should return true if the resource has a count of zero" do
        resource.stub!(:count).and_return 0
        resource.empty?.should === true
      end

      it "should return false if the resource has a count greater than zero" do
        resource.stub!(:count).and_return 10
        resource.empty?.should === false
      end
    end
  end
end

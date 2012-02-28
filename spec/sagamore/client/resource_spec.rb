require 'spec_helper'

describe Sagamore::Client::Resource do
  def parse_uri(uri)
    Addressable::URI.parse(uri)
  end

  let(:client) { Sagamore::Client.new('http://bozo.com', :username => 'un', :password => 'pw')}
  let(:session) { client.instance_variable_get(:@session) }
  let(:base_url) { "http://un:pw@bozo.com" }
  let(:resource) { Sagamore::Client::Resource.new(client, '/some/path') }

  describe "query" do
    describe "when called with a hash" do
      it "should set the query string parameters" do
        resource.query(:a => 1, :b => 2).uri.to_s.should == "/some/path?a=1&b=2"
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
          '/some/path?_filters={"a":1,"b":2}'.to_uri
      end
    end
    
    describe "when called multiple times" do
      it "should append args to _filter param as JSON array" do
        resource.filter(:a => 1).filter(:b => 2).filter(:c => 3).uri.should ==
          '/some/path?_filters=[{"a":1},{"b":2},{"c":3}]'.to_uri
      end
    end

    describe "when given a string" do
      it "should add a _filter query string param" do
        resource.filter('{"a":1,"b":2}').uri.should ==
          '/some/path?_filters={"a":1,"b":2}'.to_uri
      end
    end
  end
end


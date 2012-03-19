require 'spec_helper'

describe Sagamore::Client::Resource do
  include_context "client"

  let(:resource) { Sagamore::Client::Resource.new(client, '/some/path') }

  def parse_uri(uri)
    Addressable::URI.parse(uri)
  end

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
end


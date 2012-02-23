require 'spec_helper'

describe Sagamore::Client do
  let(:client) { Sagamore::Client.new('http://bozo.com', :username => 'un', :password => 'pw')}
  let(:session) { client.instance_variable_get(:@session) }
  let(:failed_response) do
    patron_response = Patron::Response.new
    r = Sagamore::Client::Response.new(Patron::Response.new)
  end
  let(:base_url) { "http://un:pw@bozo.com" }

  describe "session" do
    it "should receive its options from the client" do
      session.base_url.should == 'http://bozo.com'
      session.username.should == 'un'
      session.password.should == 'pw'
    end
  end

  describe "get" do
    it "should call session's get" do
      session.should_receive(:get).with('/relative/path', {})
      client.get('/relative/path')
    end
  end

  describe "get!" do
    it "should raise an exception on failure" do
      stub_request(:get, base_url+'/').to_return(:status => 404)
      lambda { client.get!('/') }.should raise_error(Sagamore::Client::RequestFailed)
    end
  end

  describe "post" do
    it "should call session's post" do
      session.should_receive(:post).with('/relative/path', 'body', {})
      client.post('/relative/path', 'body')
    end

    it "should serialize the request body as JSON if it is a hash" do
      body_hash = {:key1 => 'val1', :key2 => 'val2'}
      session.should_receive(:post).with('/path', body_hash.to_json, {})
      client.post('/path', body_hash)
    end
  end
end

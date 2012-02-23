require 'spec_helper'

describe Sagamore::Client do
  let(:client) { Sagamore::Client.new('http://bozo.com/', :username => 'abc', :password => 'secret')}
  let(:session) { client.instance_variable_get(:@session) }

  describe "get" do
    it "should call session's get" do
      session.should_receive(:get).with('/relative/path')
      client.get('/relative/path')
    end
  end

  describe "post" do
    it "should call session's post" do
      session.should_receive(:post).with('/relative/path', 'body')
      client.post('/relative/path', 'body')
    end
  end
end

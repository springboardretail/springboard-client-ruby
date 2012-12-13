require 'spec_helper'

describe Sagamore::Client::Body do
  let(:hash) { {"key1" => "val1", "key2" => {"subkey1" => "subval1"}} }
  let(:body) { Sagamore::Client::Body.new(hash)}

  describe "[]" do
    it "should support string keys" do
      body["key1"].should == "val1"
    end

    it "should support symbol keys" do
      body[:key1].should == "val1"
    end
  end

  describe "nested hashes" do
    it "should support nested indifferent access" do
      body[:key2][:subkey1].should == "subval1"
      body['key2']['subkey1'].should == "subval1"
      body[:key2]['subkey1'].should == "subval1"
      body['key2'][:subkey1].should == "subval1"
    end
  end

  describe "to_hash" do
    it "should return the original hash" do
      body.to_hash.should === hash
    end
  end
end


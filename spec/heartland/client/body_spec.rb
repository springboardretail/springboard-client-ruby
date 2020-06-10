require 'spec_helper'

describe HeartlandRetail::Client::Body do
  let(:hash) { {"key1" => "val1", "key2" => {"subkey1" => "subval1"}} }
  let(:body) { HeartlandRetail::Client::Body.new(hash)}

  describe "[]" do
    it "should support string keys" do
      expect(body["key1"]).to eq("val1")
    end

    it "should support symbol keys" do
      expect(body[:key1]).to eq("val1")
    end
  end

  describe "nested hashes" do
    it "should support nested indifferent access" do
      expect(body[:key2][:subkey1]).to eq("subval1")
      expect(body['key2']['subkey1']).to eq("subval1")
      expect(body[:key2]['subkey1']).to eq("subval1")
      expect(body['key2'][:subkey1]).to eq("subval1")
    end
  end

  describe "to_hash" do
    it "should return the original hash" do
      expect(body.to_hash).to be === hash
    end
  end
end

require 'spec_helper'

describe Sagamore::Client::Response do
  include_context "client"

  let(:body_json) { '{"key":"value"}' }
  let(:patron_response) { Patron::Response.new('/path', 200, 0, 'X-Custom-Header: Hi', body_json) }
  let(:response) { Sagamore::Client::Response.new(patron_response) }

  describe "body" do
    it "should return a Sagamore::Client::Body" do
      response.body.should be_a Sagamore::Client::Body
    end

    it "should wrap the parsed response body" do
      response.body.to_hash.should == {"key" => "value"}
    end
  end

  describe "raw_body" do
    it "should return the raw body JSON" do
      response.raw_body.should == body_json
    end
  end

  describe "[]" do
    it "should forward [] to body" do
      response.body.should_receive(:[]).with("key").and_return("value")
      response["key"].should == "value"
    end
  end

  describe "success?" do
    %w{100 101 102 200 201 202 203 204 205 206 207 208 226 300 301 302 303 304 305 306 307 308}.each do |code|
      it "should return true if the response status code is #{code}" do
        response.stub!(:status).and_return(code.to_i)
        response.success?.should === true
      end
    end

    %w{400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 420 422 423 424 425 426 428 429 431
       444 449 450 499 500 501 502 503 504 505 506 507 508 509 510 511 598 599}.each do |code|
      it "should return false if the response status code is #{code}" do
        response.stub!(:status).and_return(code.to_i)
        response.success?.should === false
      end
    end
  end
end

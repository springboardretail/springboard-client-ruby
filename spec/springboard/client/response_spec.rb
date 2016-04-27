require 'spec_helper'

describe Springboard::Client::Response do
  include_context "client"

  let(:raw_body) { '{"key":"value"}' }
  let(:raw_headers) { 'X-Custom-Header: Hi' }
  let(:status_code) { 200 }
  let(:path) { '/path' }
  let(:patron_response) do
    header_data = "HTTP/1.1 #{status_code}\r\n#{raw_headers}"
    Patron::Response.new(path, status_code, 0, header_data, raw_body)
  end
  let(:response) { Springboard::Client::Response.new(patron_response, client) }

  describe "body" do
    describe "if raw body is valid JSON" do
      it "should return a Springboard::Client::Body" do
        expect(response.body).to be_a Springboard::Client::Body
      end

      it "should wrap the parsed response body" do
        expect(response.body.to_hash).to eq({"key" => "value"})
      end
    end

    describe "if raw body is not valid JSON" do
      let(:raw_body) { 'I am not JSON!' }
      it "should raise an informative error" do
        expect { response.body }.to raise_error \
          Springboard::Client::BodyError,
          "Can't parse response body. (Hint: Try the raw_body method.)"
      end
    end

    describe "if raw body is empty" do
      let(:raw_body) { '' }
      it "should raise an informative error" do
        expect { response.body }.to raise_error \
          Springboard::Client::BodyError,
          "Response body is empty. (Hint: If you just created a new resource, try: response.resource.get)"
      end
    end
  end

  describe "raw_body" do
    it "should return the raw body JSON" do
      expect(response.raw_body).to eq(raw_body)
    end
  end

  describe "headers" do
    it "should return the response headers as a hash" do
      expect(response.headers).to eq({'X-Custom-Header' => 'Hi'})
    end
  end

  describe "resource" do
    describe "when Location header is returned" do
      let(:raw_headers) { 'Location: /new/path' }

      it "should be a Springboard::Client::Resource" do
        expect(response.resource).to be_a Springboard::Client::Resource
      end

      it "should have the Location header value as its URL" do
        expect(response.resource.uri.to_s).to eq('/new/path')
      end
    end

    describe "when Location header is not returned" do
      let(:raw_headers) { '' }

      it "should be nil" do
        expect(response.resource).to be_nil
      end
    end
  end

  describe "[]" do
    it "should forward [] to body" do
      expect(response.body).to receive(:[]).with("key").and_return("value")
      expect(response["key"]).to eq("value")
    end
  end

  describe "success?" do
    %w{100 101 102 200 201 202 203 204 205 206 207 208 226 300 301 302 303 304 305 306 307 308}.each do |code|
      it "should return true if the response status code is #{code}" do
        allow(response).to receive(:status).and_return(code.to_i)
        expect(response.success?).to be === true
      end
    end

    %w{400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 420 422 423 424 425 426 428 429 431
       444 449 450 499 500 501 502 503 504 505 506 507 508 509 510 511 598 599}.each do |code|
      it "should return false if the response status code is #{code}" do
        allow(response).to receive(:status).and_return(code.to_i)
        expect(response.success?).to be === false
      end
    end
  end
end

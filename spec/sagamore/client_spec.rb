require 'spec_helper'

describe Sagamore::Client do
  include_context "client"

  describe "session" do
    it "should be a Patron::Session" do
      client.session.should be_a Patron::Session
    end
  end

  describe "auth" do
    it "should attempt to authenticate with the given username and password" do
      request_stub = stub_request(:post, "#{base_url}/auth/identity/callback").with \
        :body => "auth_key=coco&password=boggle",
        :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}
      client.auth(:username => 'coco', :password => 'boggle')
      request_stub.should have_been_requested
    end

    it "should raise an exception if called without username or password" do
      lambda { client.auth }.should raise_error("Must specify :username and :password")
      lambda { client.auth(:username => 'x') }.should raise_error("Must specify :username and :password")
      lambda { client.auth(:password => 'y') }.should raise_error("Must specify :username and :password")
    end

    it "should return true if auth succeeds" do
      stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 200)
      lambda { client.auth(:username => 'someone', :password => 'right') }.should be_true
    end

    it "should raise an AuthFailed if auth fails" do
      stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 401)
      lambda { client.auth(:username => 'someone', :password => 'wrong') }.should \
        raise_error(Sagamore::Client::AuthFailed, "Sagamore auth failed")
    end
  end

  describe "initialize" do
    it "should call configure_session" do
      Sagamore::Client.any_instance.should_receive(:configure_session).with(base_url, {:x => 'y'})
      Sagamore::Client.new(base_url, :x => 'y')
    end
  end

  describe "configure_session" do
    it "should set the session's base_url" do
      session.should_receive(:base_url=).with(base_url)
      client.__send__(:configure_session, base_url, :x => 'y')
    end

    it "should enable cookies" do
      session.should_receive(:handle_cookies)
      client.__send__(:configure_session, base_url, :x => 'y')
    end

    it "should allow setting insecure on the session" do
      session.should_receive(:insecure=).with(true)
      client.__send__(:configure_session, base_url, :insecure => true)
    end
  end

  describe "[]" do
    it "should return a resource object with the given path and client" do
      client["path"].should be_a Sagamore::Client::Resource
    end
  end


  [:get, :head, :delete].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call session's #{method}" do
        session.should_receive(method).with('/relative/path')
        client.__send__(method, '/relative/path')
      end

      it "should return a Sagamore::Client::Response" do
        request_stub = stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path')
        response.should be_a Sagamore::Client::Response
      end

      it "should remove redundant base path prefix from URL if present" do
        request_stub = stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/api/relative/path')
        response.should be_a Sagamore::Client::Response
      end
    end

    describe bang_method do
      it "should call #{method}" do
        response = mock(Sagamore::Client::Response)
        response.should_receive(:success?).and_return(true)
        client.should_receive(method).with('/path', false).and_return(response)
        client.__send__(bang_method, '/path').should === response
      end

      it "should raise an exception on failure" do
        response = mock(Sagamore::Client::Response)
        response.should_receive(:success?).and_return(false)
        response.should_receive(:status_line).and_return('404 Not Found')
        client.should_receive(method).with('/path', false).and_return(response)
        lambda { client.send(bang_method, '/path') }.should raise_error(Sagamore::Client::RequestFailed)
      end
    end
  end


  [:put, :post].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call session's #{method}" do
        session.should_receive(method).with('/relative/path', 'body')
        client.__send__(method, '/relative/path', 'body')
      end

      it "should return a Sagamore::Client::Response" do
        request_stub = stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path', 'body')
        response.should be_a Sagamore::Client::Response
      end

      it "should serialize the request body as JSON if it is a hash" do
        body_hash = {:key1 => 'val1', :key2 => 'val2'}
        session.should_receive(method).with('/path', body_hash.to_json)
        client.__send__(method, '/path', body_hash)
      end

      it "should set the Content-Type header to application/json if not specified" do
        request_stub = stub_request(method, "#{base_url}/my/resource").
          with(:headers => {'Content-Type' => 'application/json'})
        client.__send__(method, '/my/resource', :key1 => 'val1')
        request_stub.should have_been_requested
      end

      it "should set the Content-Type header to specified value if specified" do
        request_stub = stub_request(method, "#{base_url}/my/resource").
          with(:headers => {'Content-Type' => 'application/pdf'})
        client.__send__(method, '/my/resource', {:key1 => 'val1'}, 'Content-Type' => 'application/pdf')
        request_stub.should have_been_requested
      end
    end

    describe bang_method do
      it "should call #{method}" do
        response = mock(Sagamore::Client::Response)
        response.should_receive(:success?).and_return(true)
        client.should_receive(method).with('/path', 'body', false).and_return(response)
        client.__send__(bang_method, '/path', 'body').should === response
      end

      it "should raise an exception on failure" do
        response = mock(Sagamore::Client::Response)
        response.should_receive(:success?).and_return(false)
        response.should_receive(:status_line).and_return('404 Not Found')
        client.should_receive(method).with('/path', 'body', false).and_return(response)
        expect { client.send(bang_method, '/path', 'body') }.to raise_error { |error|
          error.should be_a(Sagamore::Client::RequestFailed)
          error.response.should === response
        }
      end
    end
  end
end

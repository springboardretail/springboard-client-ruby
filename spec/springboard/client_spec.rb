require 'spec_helper'

describe Springboard::Client do
  include_context "client"

  describe "session" do
    it "should be a Patron::Session" do
      expect(client.session).to be_a Patron::Session
    end
  end

  describe "auth" do
    it "should attempt to authenticate with the given username and password" do
      request_stub = stub_request(:post, "#{base_url}/auth/identity/callback").with \
        :body => "auth_key=coco&password=boggle",
        :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}
      client.auth(:username => 'coco', :password => 'boggle')
      expect(request_stub).to have_been_requested
    end

    it "should raise an exception if called without username or password" do
      expect { client.auth }.to raise_error("Must specify :username and :password")
      expect { client.auth(:username => 'x') }.to raise_error("Must specify :username and :password")
      expect { client.auth(:password => 'y') }.to raise_error("Must specify :username and :password")
    end

    it "should return true if auth succeeds" do
      stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 200)
      expect(client.auth(:username => 'someone', :password => 'right')).to be_truthy
    end

    it "should raise an AuthFailed if auth fails" do
      stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 401)
      expect { client.auth(:username => 'someone', :password => 'wrong') }.to \
        raise_error(Springboard::Client::AuthFailed, "Springboard auth failed")
    end
  end

  describe "initialize" do
    it "should call configure_session" do
      expect_any_instance_of(Springboard::Client).to receive(:configure_session).with(base_url, {:x => 'y'})
      Springboard::Client.new(base_url, :x => 'y')
    end
  end

  describe "configure_session" do
    it "should set the session's base_url" do
      expect(session).to receive(:base_url=).with(base_url)
      client.__send__(:configure_session, base_url, :x => 'y')
    end

    it "should enable cookies" do
      expect(session).to receive(:handle_cookies)
      client.__send__(:configure_session, base_url, :x => 'y')
    end

    it "should allow setting insecure on the session" do
      expect(session).to receive(:insecure=).with(true)
      client.__send__(:configure_session, base_url, :insecure => true)
    end

    it "set the default timeout" do
      client.__send__(:configure_session, base_url, {})
      expect(client.session.timeout).to eq(Springboard::Client::DEFAULT_TIMEOUT)
    end

    it "set the default connect timeout" do
      client.__send__(:configure_session, base_url, {})
      expect(client.session.connect_timeout).to eq(Springboard::Client::DEFAULT_CONNECT_TIMEOUT)
    end

    context 'headers' do
      let(:headers) { double('headers') }
      before do
        allow(session).to receive(:headers).and_return(headers)
      end

      it 'sets Content-Type header' do
        expect(headers).to receive(:[]=).once.with('Content-Type', 'application/json')
        expect(headers).to receive(:[]=).once.with('Authorization', 'Bearer token')
        client.__send__(:configure_session, base_url, :token => 'token')
      end
    end
  end

  describe "[]" do
    it "should return a resource object with the given path and client" do
      expect(client["path"]).to be_a Springboard::Client::Resource
    end
  end

  describe "debug=" do
    context "with a file path" do
      it "should pass the path to enable_debug on the Patron session" do
        expect(client.session).to receive(:enable_debug).with('/path/to/log')
        client.debug = '/path/to/log'
      end
    end

    context "with true" do
      it "should pass nil to enable_debug on the Patron session" do
        expect(client.session).to receive(:enable_debug).with(nil)
        client.debug = true
      end
    end
  end

  [:get, :head, :delete].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call session's #{method}" do
        expect(session).to receive(method).with('/relative/path')
        client.__send__(method, '/relative/path')
      end

      it "should return a Springboard::Client::Response" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path')
        expect(response).to be_a Springboard::Client::Response
      end

      it "should remove redundant base path prefix from URL if present" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/api/relative/path')
        expect(response).to be_a Springboard::Client::Response
      end
    end

    describe bang_method do
      it "should call #{method}" do
        response = double(Springboard::Client::Response)
        expect(response).to receive(:success?).and_return(true)
        expect(client).to receive(method).with('/path', false).and_return(response)
        expect(client.__send__(bang_method, '/path')).to be === response
      end

      it "should raise an exception on failure" do
        response = double(Springboard::Client::Response)
        expect(response).to receive(:success?).and_return(false)
        expect(response).to receive(:status_line).and_return('404 Not Found')
        expect(client).to receive(method).with('/path', false).and_return(response)
        expect { client.send(bang_method, '/path') }.to raise_error(Springboard::Client::RequestFailed)
      end
    end
  end


  [:put, :post].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call session's #{method}" do
        expect(session).to receive(method).with('/relative/path', 'body')
        client.__send__(method, '/relative/path', 'body')
      end

      it "should return a Springboard::Client::Response" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path', 'body')
        expect(response).to be_a Springboard::Client::Response
      end

      it "should serialize the request body as JSON if it is a hash" do
        body_hash = {:key1 => 'val1', :key2 => 'val2'}
        expect(session).to receive(method).with('/path', body_hash.to_json)
        client.__send__(method, '/path', body_hash)
      end

      it "should set the Content-Type header to application/json if not specified" do
        request_stub = stub_request(method, "#{base_url}/my/resource").
          with(:headers => {'Content-Type' => 'application/json'})
        client.__send__(method, '/my/resource', :key1 => 'val1')
        expect(request_stub).to have_been_requested
      end

      it "should set the Content-Type header to specified value if specified" do
        request_stub = stub_request(method, "#{base_url}/my/resource").
          with(:headers => {'Content-Type' => 'application/pdf'})
        client.__send__(method, '/my/resource', {:key1 => 'val1'}, 'Content-Type' => 'application/pdf')
        expect(request_stub).to have_been_requested
      end
    end

    describe bang_method do
      it "should call #{method}" do
        response = double(Springboard::Client::Response)
        expect(response).to receive(:success?).and_return(true)
        expect(client).to receive(method).with('/path', 'body', false).and_return(response)
        expect(client.__send__(bang_method, '/path', 'body')).to be === response
      end

      it "should raise an exception on failure" do
        response = double(Springboard::Client::Response)
        expect(response).to receive(:success?).and_return(false)
        expect(response).to receive(:status_line).and_return('404 Not Found')
        expect(client).to receive(method).with('/path', 'body', false).and_return(response)
        expect { client.send(bang_method, '/path', 'body') }.to raise_error { |error|
          expect(error).to be_a(Springboard::Client::RequestFailed)
          expect(error.response).to be === response
        }
      end
    end
  end

  describe "each_page" do
    it "should request each page of the collection and yield each response to the block" do
      responses = (1..3).map do |p|
        response = double(Springboard::Client::Response)
        allow(response).to receive(:[]).with('pages').and_return(3)

        expect(client).to receive(:get!).with("/things?page=#{p}&per_page=20".to_uri).and_return(response)

        response
      end

      expect do |block|
        client.each_page('/things', &block)
      end.to yield_successive_args(*responses)
    end
  end

  describe "each" do
    it "should request each page of the collection and yield each individual result to the block" do
      all_results = (1..3).inject([]) do |results, p|
        response = double(Springboard::Client::Response)
        allow(response).to receive(:[]).with('pages').and_return(3)

        page_results = 20.times.map {|i| "Page #{p} result #{i+1}"}
        results += page_results

        allow(response).to receive(:[]).with('results').and_return(page_results)

        expect(client).to receive(:get!).with("/things?page=#{p}&per_page=20".to_uri).and_return(response)

        results
      end

      expect do |block|
        client.each('/things', &block)
      end.to yield_successive_args(*all_results)
    end
  end

  describe "count" do
    it "should request the first page/record of the collection and return the total" do
      response = double(Springboard::Client::Response)
      allow(response).to receive(:[]).with('total').and_return(17)
      expect(client).to receive(:get!).with("/things?page=1&per_page=1".to_uri)
        .and_return(response)
      expect(client.count('/things')).to eq(17)
    end
  end
end

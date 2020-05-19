require 'spec_helper'

describe HeartlandRetail::Client do
  include_context "client"

  describe "connection" do
    it "should be a Faraday::Connection" do
      expect(client.connection).to be_a Faraday::Connection
    end
  end

  describe "auth" do
    it "should attempt to authenticate with the given username and password" do
      request_stub = stub_request(:post, "#{base_url}/auth/identity/callback").with(
        :body => "auth_key=coco&password=boggle",
        :headers => {'Content-Type' => 'application/x-www-form-urlencoded'}
      )

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
        raise_error(HeartlandRetail::Client::AuthFailed, "Heartland Retail auth failed")
    end

    it "should store the session cookie" do
      stub_request(:post, "#{base_url}/auth/identity/callback").to_return(headers: {'set-cookie' => '123'})
      client.auth(:username => 'someone', :password => 'right')
      expect(client.instance_variable_get(:@session_cookie)).to eq('123')
    end
  end

  describe "initialize" do
    it "should call configure_connection!" do
      expect_any_instance_of(HeartlandRetail::Client).to receive(:configure_connection!)
      HeartlandRetail::Client.new(base_url, :x => 'y')
    end
  end

  describe "configure_connection" do
    it "should set the connection's url_prefix" do
      client.__send__(:configure_connection!)
      expect(connection.url_prefix.to_s).to eq(base_url)
    end

    it "should allow setting insecure on the connection" do
      client.__send__(:opts)[:insecure] = true
      client.__send__(:configure_connection!)
      expect(connection.ssl[:verify]).to be false
    end

    it "set the default timeout" do
      client.__send__(:configure_connection!)
      expect(connection.options.timeout).to eq(HeartlandRetail::Client::DEFAULT_TIMEOUT)
    end

    it "set the default connect timeout" do
      client.__send__(:configure_connection!)
      expect(connection.options.open_timeout).to eq(HeartlandRetail::Client::DEFAULT_CONNECT_TIMEOUT)
    end

    context 'headers' do
      let(:headers) { double('headers') }
      before do
        connection = double('Connection').as_null_object
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:headers).and_return(headers)
      end

      it 'sets Content-Type header' do
        expect(headers).to receive(:[]=).once.with('Content-Type', 'application/json')
        expect(headers).to receive(:[]=).once.with('Authorization', 'Bearer token')
        HeartlandRetail::Client.new(base_url, token: 'token')
      end
    end
  end

  describe "[]" do
    it "should return a resource object with the given path string and client" do
      expect(client["path"]).to be_a HeartlandRetail::Client::Resource
      expect(client[:path].uri.to_s).to eq("#{base_url}/path")
    end

    it "should return a resource object when given a path as a symbol" do
      expect(client[:path]).to be_a HeartlandRetail::Client::Resource
      expect(client[:path].uri.to_s).to eq("#{base_url}/path")
    end

    it "should return a resource object when given a path as a URI" do
      uri = 'path'.to_uri
      expect(client[uri]).to be_a HeartlandRetail::Client::Resource
      expect(client[uri].uri.to_s).to eq("#{base_url}/path")
    end

    it "should not duplicate the base URI path" do
      expect(client['api/subpath'].uri.to_s).to eq("#{base_url}/subpath")
    end

    it "should not duplicate the base URI" do
      expect(client["#{base_url}/subpath"].uri.to_s).to eq("#{base_url}/subpath")
    end
  end

  describe "debug=" do
    it "should set opts[:debug]" do
      logger = double
      allow(Logger).to receive(:new).with('/path/to/log').and_return(logger)

      client.debug = '/path/to/log'
      expect(client.__send__(:opts)[:debug]).to eq('/path/to/log')
    end

    it "should reconfigure connection" do
      logger = double
      allow(Logger).to receive(:new).with('/path/to/log').and_return(logger)

      expect(client).to receive(:configure_connection!)
      client.debug = '/path/to/log'
    end
  end

  [:get, :head, :delete].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call connection's #{method}" do
        expect(connection).to receive(method).with('relative/path')

        client.__send__(method, '/relative/path')
      end

      it "should return a HeartlandRetail::Client::Response" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path')
        expect(response).to be_a HeartlandRetail::Client::Response
      end

      it "should remove redundant base path prefix from URL if present" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/api/relative/path')
        expect(response).to be_a HeartlandRetail::Client::Response
      end
    end

    describe bang_method do
      it "should call #{method}" do
        response = double(HeartlandRetail::Client::Response)
        expect(response).to receive(:success?).and_return(true)
        expect(client).to receive(method).with('/path', false).and_return(response)
        expect(client.__send__(bang_method, '/path')).to be === response
      end

      it "should raise an exception on failure" do
        response = double(HeartlandRetail::Client::Response)
        expect(response).to receive(:success?).and_return(false)
        expect(response).to receive(:status).and_return(404)
        expect(client).to receive(method).with('/path', false).and_return(response)
        expect { client.send(bang_method, '/path') }.to raise_error(HeartlandRetail::Client::RequestFailed)
      end
    end
  end

  [:put, :post].each do |method|
    bang_method = "#{method}!"
    describe method do
      it "should call connection's #{method}" do
        request = double.as_null_object

        expect(request).to receive(:body=).with('body')
        expect(connection).to receive(method).with('relative/path').and_yield(request)

        client.__send__(method, '/relative/path', 'body')
      end

      it "should return a HeartlandRetail::Client::Response" do
        stub_request(method, "#{base_url}/relative/path")
        response = client.__send__(method, '/relative/path', 'body')
        expect(response).to be_a HeartlandRetail::Client::Response
      end

      it "should serialize the request body as JSON if it is a hash" do
        request = double.as_null_object
        body_hash = {:key1 => 'val1', :key2 => 'val2'}

        expect(connection).to receive(method).and_yield(request)
        expect(request).to receive(:body=).with(body_hash.to_json)

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
        response = double(HeartlandRetail::Client::Response)
        expect(response).to receive(:success?).and_return(true)
        expect(client).to receive(method).with('/path', 'body', false).and_return(response)
        expect(client.__send__(bang_method, '/path', 'body')).to be === response
      end

      it "should raise an exception on failure" do
        response = double(HeartlandRetail::Client::Response)
        expect(response).to receive(:success?).and_return(false)
        expect(response).to receive(:status).and_return(404)
        expect(client).to receive(method).with('/path', 'body', false).and_return(response)
        expect { client.send(bang_method, '/path', 'body') }.to raise_error { |error|
          expect(error).to be_a(HeartlandRetail::Client::RequestFailed)
          expect(error.response).to be === response
        }
      end
    end
  end

  describe "each_page" do
    it "should request each page of the collection and yield each response to the block" do
      responses = (1..3).map do |p|
        response = double(HeartlandRetail::Client::Response)
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
        response = double(HeartlandRetail::Client::Response)
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
      response = double(HeartlandRetail::Client::Response)
      allow(response).to receive(:[]).with('total').and_return(17)
      expect(client).to receive(:get!).with("/things?page=1&per_page=1".to_uri)
        .and_return(response)
      expect(client.count('/things')).to eq(17)
    end
  end
end

describe Springboard::Client do
  include_context "client"
  let(:client) { Springboard::Client.new(base_url) }

  describe "initialize" do
    it "should call configure_connection! and return a HeartlandRetail::Client" do
      expect_any_instance_of(HeartlandRetail::Client).to receive(:configure_connection!)
      client = Springboard::Client.new(base_url, :x => 'y')
      expect(client).to be_a HeartlandRetail::Client
    end

    it "should include a deprecation warning" do
      deprecation_message = "[DEPRECATION] `Springboard::Client.new` is deprecated. Please use `HeartlandRetail::Client.new` instead.\n"
      expect { Springboard::Client.new(base_url) }.to output(deprecation_message).to_stderr 
    end
  end

  describe "errors" do
    describe "legacy error handling" do
      describe "AuthFailed" do
        it "should raise a Springboard class error if auth fails" do
          stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 401)
          expect { client.auth(:username => 'someone', :password => 'wrong') }.to \
          raise_error(Springboard::Client::AuthFailed, "Heartland Retail auth failed")
        end

        it "should rescue a Springboard class error" do
          stub_request(:post, "#{base_url}/auth/identity/callback").to_return(:status => 401)
          rescued = nil
          begin
            client.auth(:username => 'someone', :password => 'wrong')
          rescue Springboard::Client::AuthFailed => err
            rescued = true
          end
          expect(rescued).to eq(true)
        end
      end
      
      describe "RequestFailed" do
        it "should raise an Springboard class error if request fails" do
          response = double(Springboard::Client::Response)
          expect(response).to receive(:success?).and_return(false)
          expect(response).to receive(:status).and_return(404)
          expect(client).to receive(:get).with('/path', false).and_return(response)
          expect { client.get!('/path') }.to raise_error(Springboard::Client::RequestFailed)
        end

        it "should rescue a Springboard class error" do
          response = double(Springboard::Client::Response)
          expect(response).to receive(:success?).and_return(false)
          expect(response).to receive(:status).and_return(404)
          expect(client).to receive(:get).with('/path', false).and_return(response)
          rescued = nil
          begin
            client.get!('/path')
          rescue Springboard::Client::RequestFailed => err
            rescued = true
          end
          expect(rescued).to eq(true)
        end
      end
    end
  end

  [:get, :head, :delete, :put, :post, :debug=, :[], :auth, :connection].each do |method|
    describe method do
      it "should respond to the HeartlandRetail::Client method #{method}" do
        expect(client).to respond_to(method)
      end
    end
  end
end

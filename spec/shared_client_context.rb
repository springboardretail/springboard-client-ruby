shared_context "client" do
  let(:base_url) { "http://bozo.com/api" }
  let(:client) { Springboard::Client.new(base_url) }
  let(:connection) { client.connection }
end

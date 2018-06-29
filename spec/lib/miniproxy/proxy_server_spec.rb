require "miniproxy/proxy_server"

RSpec.describe MiniProxy::ProxyServer do
  describe "#service" do
    let(:proxy_server) {
      MiniProxy::ProxyServer.new(
        Port: (12345..32768).to_a.sample,
        FakeServerPort: 33333,
        MockHandlerCallback: handler
      )
    }
    let(:res) { MiniProxy::Stub::Response.new(headers: [], body: "") }
    let(:handler) { double(:handler) }

    describe "requests to localhost" do
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "GET", unparsed_uri: "http://localhost/", host: "localhost") }

      it "performs the request" do
        expect(proxy_server).to receive(:proxy_service).with(req, res)
        proxy_server.service(req, res)
      end
    end

    describe "SSL requests" do
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "https://example.com/", host: "example.com") }
      let(:req_unparsed_uri) { req.instance_variable_get(:@unparsed_uri) }

      it "rewrites the request to point to our fake SSL server" do
        allow(proxy_server).to receive(:do_CONNECT)
        proxy_server.service(req, res)
        expect(req_unparsed_uri).to eq "localhost:33333"
      end

      it "performs the request" do
        expect(proxy_server).to receive(:do_CONNECT).with(req, res)
        proxy_server.service(req, res)
      end
    end

    describe "non-SSL requests to remote hosts" do
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "GET", unparsed_uri: "http://example.com/", host: "example.com") }

      it "calls the mock handler" do
        expect(handler).to receive(:call).with(req, res)
        proxy_server.service(req, res)
      end
    end
  end
end

require "miniproxy/fake_ssl_server"

RSpec.describe MiniProxy::FakeSSLServer do
  describe "#service" do
    let(:host) { "123.45.65.43" }
    let(:fake_ssl_server) {
      MiniProxy::FakeSSLServer.new(
        MiniProxyHost: host,
        Port: (12345..32768).to_a.sample,
        MockHandlerCallback: handler,
      )
    }
    let(:res) { MiniProxy::Stub::Response.new(headers: [], body: "") }
    let(:handler) { double(:handler) }

    describe "requests to localhost" do
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "https://#{host}/", host: host, path: "/") }
      let(:servlet) { double(:servlet, get_instance: servlet_instance) }
      let(:servlet_instance) { double(:servlet_instance) }

      before do
        allow(req).to receive(:script_name=)
        allow(req).to receive(:path_info=)
      end

      it "performs the request" do
        expect(fake_ssl_server).to receive(:search_servlet).and_return(servlet)
        expect(servlet_instance).to receive(:service).with(req, res)
        fake_ssl_server.service(req, res)
      end
    end

    describe "requests to remote hosts" do
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "https://example.com/", host: "example.com") }

      it "calls the mock handler" do
        expect(handler).to receive(:call).with(req, res)
        fake_ssl_server.service(req, res)
      end
    end
  end
end

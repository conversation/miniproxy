require "miniproxy/proxy_server"
require "support/server"

RSpec.describe MiniProxy::ProxyServer do
  describe "#service" do
    let(:allowed_request_check) { ->(req) { false } }
    let(:proxy_server) {
      MiniProxy::ProxyServer.new(
        AllowedRequestCheck: allowed_request_check,
        Port: (12345..32768).to_a.sample,
        FakeServerPort: 33333,
        MockHandlerCallback: handler,
        MiniproxyConfig: double(allow_external_requests: false)
      )
    }
    let(:res) { MiniProxy::Stub::Response.new(headers: [], body: "") }
    let(:handler) { double(:handler) }

    context "when the request is allowed" do
      let(:allowed_request_check) { ->(req) { true } }
      let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "GET", unparsed_uri: "http://localhost/", host: "localhost") }

      it "performs the request" do
        expect(proxy_server).to receive(:proxy_service).with(req, res)
        proxy_server.service(req, res)
      end
    end

    context "when the request is not allowed" do
      describe "SSL CONNECT requests" do
        let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "https://example.com:443", host: "example.com") }
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

      describe "non-SSL CONNECT requests" do
        let(:req) { instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "example.com:1234", host: "example.com") }
        let(:req_unparsed_uri) { req.instance_variable_get(:@unparsed_uri) }

        it "does not rewrite the request to point to our fake SSL server" do
          allow(proxy_server).to receive(:do_CONNECT)
          proxy_server.service(req, res)
          expect(req_unparsed_uri).to eq nil
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

  describe "passing through requests" do
    it "suports GET requests" do
      with_proxied_echo_server do |http|
        req = Net::HTTP::Get.new("/")
        http.request(req) do |res|
          expect(res.body).to eq("GET / ")
        end
      end
    end

    it "suports POST requests" do
      with_proxied_echo_server do |http|
        req = Net::HTTP::Post.new("/")
        req.body = "post-data"
        http.request(req) do |res|
          expect(res.body).to eq("POST / post-data")
        end
      end
    end

    it "suports PUT requests" do
      with_proxied_echo_server do |http|
        req = Net::HTTP::Put.new("/")
        req.body = "put-data"
        http.request(req) do |res|
          expect(res.body).to eq("PUT / put-data")
        end
      end
    end

    it "suports PATCH requests" do
      with_proxied_echo_server do |http|
        req = Net::HTTP::Patch.new("/")
        req.body = "patch-data"
        http.request(req) do |res|
          expect(res.body).to eq("PATCH / patch-data")
        end
      end
    end

    it "suports DELETE requests" do
      with_proxied_echo_server do |http|
        req = Net::HTTP::Delete.new("/")
        http.request(req) do |res|
          expect(res.body).to eq("DELETE / ")
        end
      end
    end
  end
end

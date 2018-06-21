require "miniproxy/remote"

describe MiniProxy::Remote do
  describe "#handler" do
    let(:remote) { MiniProxy::Remote.new }

    context "when the request has not been mocked" do
      let(:req) { double(:request, request_method: 'GET', host: 'example.com', path: '/') }
      let(:res) { WEBrick::HTTPResponse.new(WEBrick::Config::HTTP) }

      it "outputs an error message" do
        expect(STDOUT).to receive(:puts).with("WARN: external request to example.com/ not mocked")
        expect(STDOUT).to receive(:puts).with(%q(Stub with: MiniProxy::Server.stub_request(method: "GET", url: "example.com/")))

        remote.handler(req, res)
      end
    end
  end
end

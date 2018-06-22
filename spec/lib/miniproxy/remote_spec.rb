require "miniproxy/remote"

describe MiniProxy::Remote do
  let(:remote) { MiniProxy::Remote.new }

  describe "#handler" do
    context "when the request has not been mocked" do
      let(:req) { double(:request, request_method: 'GET', host: 'example.com', path: '/') }
      let(:res) { WEBrick::HTTPResponse.new(WEBrick::Config::HTTP) }

      it "queues error messages" do
        remote.handler(req, res)

        expect(remote.drain_messages).to eql [
          "WARN: external request to example.com/ not mocked",
          %q(Stub with: MiniProxy::Server.stub_request(method: "GET", url: "example.com/"))
        ]
      end
    end
  end

  describe "#drain_messages" do
    context "queued messages" do
      before do
        remote.instance_variable_set(:@messages, ["hello", "world"])
      end

      it "drains queued messages" do
        expect(remote.drain_messages).to eql ["hello", "world"]
        expect(remote.drain_messages).to be_empty
      end
    end

    context "no queued messages" do
      it "returns an empty array" do
        expect(remote.drain_messages).to eql []
      end
    end
  end
end

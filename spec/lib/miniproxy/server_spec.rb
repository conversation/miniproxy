require "miniproxy/server"
require "miniproxy/remote"

RSpec.describe MiniProxy::Server do
  let(:remote_stub) { instance_double(MiniProxy::Remote) }

  before do
    allow(MiniProxy::Server).to receive(:remote).and_return remote_stub
  end

  describe ".reset" do
    it "calls clear on the remote object" do
      expect(remote_stub).to receive(:clear)
      MiniProxy::Server.reset
    end
  end

  describe ".stop" do
    context "drb process alive" do
      before do
        allow(MiniProxy::Remote).to receive(:drb_process_alive?).and_return true
      end

      it "calls stop on the remote object" do
        expect(remote_stub).to receive(:stop)
        MiniProxy::Server.stop
      end
    end

    context "drb process not alive" do
      before do
        allow(MiniProxy::Remote).to receive(:drb_process_alive?).and_return false
      end

      it "does not call stop on the remote object" do
        expect(remote_stub).to_not receive(:stop)
        MiniProxy::Server.stop
      end
    end
  end

  describe ".port" do
    it "calls port on the remote object" do
      expect(remote_stub).to receive(:port)
      MiniProxy::Server.port
    end
  end

  describe ".host" do
    it "returns '127.0.0.1'" do
      expect(MiniProxy::Server.host).to eql "127.0.0.1"
    end
  end

  describe ".stub_request" do
    it "calls stub_request on the remote object with the given arguments" do
      expect(remote_stub).to receive(:stub_request).with(method: "GET", url: "namco.co.jp", response: { body: "765" })
      MiniProxy::Server.stub_request(method: "GET", url: "namco.co.jp", response: { body: "765" })
    end
  end
end

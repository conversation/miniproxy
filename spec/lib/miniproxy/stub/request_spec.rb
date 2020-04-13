require "miniproxy/stub/request"
require "webrick"

RSpec.describe MiniProxy::Stub::Request do
  let(:request) { MiniProxy::Stub::Request.new(method: "GET", url: "google.com/search", response: {}) }

  describe "#match?" do
    context "request method does not match" do
      let(:http_request) { instance_double(WEBrick::HTTPRequest, request_method: "POST", host: "x", path: "x") }

      it "returns false" do
        expect(request.match?(http_request)).to eql false
      end
    end

    context "request method matches" do
      context "request uri does not match" do
        let(:http_request) { instance_double(WEBrick::HTTPRequest, request_method: "GET", host: "google.com/", path: "sign_in") }

        it "returns false" do
          expect(request.match?(http_request)).to eql false
        end
      end

      context "request uri matches" do
        let(:http_request) { instance_double(WEBrick::HTTPRequest, request_method: "GET", host: "google.com/", path: "search") }

        it "returns true" do
          expect(request.match?(http_request)).to eql true
        end
      end
    end

    context "CONNECT requests" do
      it "returns true when it matches the host" do
        http_request = instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "google.com:443") 

        expect(request.match?(http_request)).to eq(true)
      end

      it "returns false when it does not match the host" do
        http_request = instance_double(WEBrick::HTTPRequest, request_method: "CONNECT", unparsed_uri: "example.com:443") 

        expect(request.match?(http_request)).to eq(false)
      end
    end
  end
end

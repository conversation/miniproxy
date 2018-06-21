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
  end
end

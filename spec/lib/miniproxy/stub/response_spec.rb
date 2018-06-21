require "miniproxy/stub/response"

RSpec.describe MiniProxy::Stub::Response do
  describe "#body" do
    context "@body is set" do
      let(:response) { MiniProxy::Stub::Response.new(headers: nil, body: "yolo") }

      it "returns body" do
        expect(response.body).to eql "yolo"
      end
    end

    context "@body is not set" do
      let(:response) { MiniProxy::Stub::Response.new(headers: nil, body: nil) }

      it "returns an empty string" do
        expect(response.body).to eql ""
      end
    end
  end

  describe "#code" do
    let(:response) { MiniProxy::Stub::Response.new(headers: nil, body: nil) }

    it "returns 200" do
      expect(response.code).to eql 200
    end
  end

  describe "#headers" do
    context "@headers is set" do
      let(:response) { MiniProxy::Stub::Response.new(headers: { hello: "world" }, body: nil) }

      it "returns headers" do
        expect(response.headers).to eql({ hello: "world" })
      end
    end

    context "@headers is not set" do
      let(:response) { MiniProxy::Stub::Response.new(headers: nil, body: nil) }

      it "returns a default hash with Content-Type 'text/html'" do
        expect(response.headers).to eql({ "Content-Type" => "text/html" })
      end
    end
  end
end

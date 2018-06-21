require "capybara"
require "miniproxy"
require "support/capybara_driver"

RSpec.describe "miniproxy" do
  let(:session) { Capybara::Session.new(:firefox) }

  describe "ignoring all requests" do
    context "without any previous stubs" do
      before do
        MiniProxy::Server.ignore_all_requests
      end

      after do
        MiniProxy::Server.reset
      end

      it "intercepts the request and returns an empty response" do
        session.visit("http://example.com/resource.txt")
        expect_empty_response
      end
    end

    context "with a previously defined stub" do
      before do
        MiniProxy::Server.stub_request(method: "GET", url: /example.com/, response: { body: "foo" })
        MiniProxy::Server.ignore_all_requests
      end

      after do
        MiniProxy::Server.reset
      end

      it "intercepts the request and returns an empty response" do
        session.visit("http://example.com/resource.txt")
        expect_empty_response
      end
    end
  end

  private

  def expect_empty_response
    expect(session.html).to eq "<html><head></head><body></body></html>"
  end
end

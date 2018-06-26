require "capybara"
require "miniproxy"
require "support/capybara_driver"

RSpec.describe "miniproxy" do
  let(:session) { Capybara::Session.new(:firefox) }

  describe "allowing external requests" do
    before { MiniProxy::Server.set_config :allow_external_requests, true }
    after { MiniProxy::Server.set_config :allow_external_requests, false }


    it "hits the internet" do
      session.visit("http://example.com")
      expect(session).to have_content "Example Domain"
    end

    context "when a stub is set" do
      before do
        MiniProxy::Server.stub_request(method: "GET", url: /example.com/, response: { body: "foo" })
      end

      after do
        MiniProxy::Server.reset
      end

      it "uses the stub rather than hitting the internet" do
        session.visit("http://example.com")
        expect(session).to have_content "foo"
        expect(session).not_to have_content "Example Domain"
      end
    end
  end
end

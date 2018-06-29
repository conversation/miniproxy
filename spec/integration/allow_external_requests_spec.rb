require "capybara"
require "miniproxy"
require "support/capybara_driver"

RSpec.describe "miniproxy" do
  let(:session) { Capybara::Session.new(:firefox) }

  describe "allowing external requests" do
    before { MiniProxy.allow_external_requests = true }
    after { MiniProxy.allow_external_requests = false }

    it "hits the internet" do
      session.visit("http://example.com")
      expect(session).to have_content "Example Domain"
    end

    context "when a stub is set" do
      before do
        MiniProxy.stub_request(method: "GET", url: /example.com/, response: { body: "foo" })
      end

      after do
        MiniProxy.reset
      end

      it "uses the stub rather than hitting the internet" do
        session.visit("http://example.com")
        expect(session).to have_content "foo"
        expect(session).not_to have_content "Example Domain"
      end
    end

    describe "alternating configuration on the fly" do
      it "works as expected when toggling allow_external_requests" do
        MiniProxy.allow_external_requests = true

        session.visit("http://example.com")
        expect(session).to have_content "Example Domain"

        MiniProxy.allow_external_requests = false

        expect {
          session.visit("http://foo.com")
          MiniProxy.reset
        }.to output(/WARN/).to_stdout_from_any_process
      end
    end
  end
end

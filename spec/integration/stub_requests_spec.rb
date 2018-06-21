require "capybara"
require "miniproxy"
require "selenium-webdriver"

firefox_profile = Selenium::WebDriver::Firefox::Profile.new
firefox_profile.assume_untrusted_certificate_issuer = true
firefox_profile.proxy = Selenium::WebDriver::Proxy.new(
  http: "#{MiniProxy::Server.host}:#{MiniProxy::Server.port}",
  ssl: "#{MiniProxy::Server.host}:#{MiniProxy::Server.port}"
)

firefox_options = Selenium::WebDriver::Firefox::Options.new(profile: firefox_profile)
firefox_options.headless!

firefox_caps = Selenium::WebDriver::Remote::Capabilities.firefox(accept_insecure_certs: true)

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, desired_capabilities: firefox_caps, options: firefox_options)
end

RSpec.describe "miniproxy" do
  let(:session) { Capybara::Session.new(:firefox) }

  describe "http request" do

    context "stubbed" do
      before do
        MiniProxy::Server.stub_request(method: "GET", url: /example.com/, response: { body: "foo" })
      end

      after do
        MiniProxy::Server.reset
      end

      it "intercepts the request and returns the mock response" do
        session.visit("http://example.com/resource.txt")
        expect(session).to have_content "foo"
      end
    end

    context "not stubbed" do
      it "intercepts the request and prints a warning to stdout", :pending do
        expect {
          session.visit("http://example.com")
        }.to output(/WARN/).to_stdout_from_any_process
      end
    end
  end

  describe "https request" do
    context "stubbed" do
      before do
        MiniProxy::Server.stub_request(method: "GET", url: /example.com/, response: { body: "foo" })
      end

      after do
        MiniProxy::Server.reset
      end

      it "intercepts the request and returns the mock response" do
        session.visit("https://example.com/resource.txt")
        expect(session).to have_content "foo"
      end
    end

    context "not stubbed" do
      it "intercepts the request and prints a warning to stdout", :pending do
        expect {
          session.visit("http://example.com")
        }.to output(/WARN/).to_stdout_from_any_process
      end
    end
  end
end

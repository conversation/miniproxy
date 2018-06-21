require "capybara"
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

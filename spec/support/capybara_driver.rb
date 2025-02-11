require "capybara"
require "selenium-webdriver"

firefox_profile = Selenium::WebDriver::Firefox::Profile.new
firefox_profile.secure_ssl = false
firefox_profile.proxy = Selenium::WebDriver::Proxy.new(
  http: "#{MiniProxy.host}:#{MiniProxy.port}",
  ssl: "#{MiniProxy.host}:#{MiniProxy.port}"
)

# disabling these features ensures no automatic requests by firefox are made
# ref: https://bugzilla.mozilla.org/show_bug.cgi?id=1410586
firefox_profile["browser.chrome.favicons"] = false
firefox_profile["privacy.trackingprotection.annotate_channels"] = false
firefox_profile["privacy.trackingprotection.enabled"] = false
firefox_profile["privacy.trackingprotection.pbmode.enabled"] = false
firefox_profile["plugins.flashBlock.enabled"] = false
firefox_profile["browser.safebrowsing.blockedURIs.enable"] = false

firefox_options = Selenium::WebDriver::Firefox::Options.new(
  profile: firefox_profile,
  args: ['-headless'],
)

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, options: firefox_options)
end

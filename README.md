# MiniProxy [![Build Status](https://travis-ci.org/conversation/miniproxy.svg?branch=master)](https://travis-ci.org/conversation/miniproxy)

A small stubbable proxy server for testing HTTP(S) interactions.


## Getting Started

In your Gemfile:

    gem 'miniproxy'

Configure Capybara (via Chrome and Selenium) to route all requests through the server (`spec/support/capybara_driver.rb`):

    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument("--proxy-server=#{MiniProxy::Server.host}:#{MiniProxy::Server.port}")

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
    end

Make sure that RSpec resets the server after each test, and stops the server when the suite is finished (`spec/support/mini_proxy.rb`):

    require "miniproxy"

    RSpec.configure do |config|
      config.after :each, type: :feature do
        MiniProxy::Server.reset
      end

      config.after :suite do
        MiniProxy::Server.stop
      end
    end

In your specs, to stub a request:

    MiniProxy::Server.stub_request(method: "POST", url: /example.com/, response: {
      headers: { "Foo" => "bar" },
      code: 200,
      body: "hello",
    })


## Testing MiniProxy itself

Tests are run via RSpec:

    rspec spec

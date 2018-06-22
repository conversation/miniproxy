# MiniProxy [![Build Status](https://travis-ci.org/conversation/miniproxy.svg?branch=master)](https://travis-ci.org/conversation/miniproxy)

A small stubbable proxy server for testing HTTP(S) interactions.


## Getting Started

In your Gemfile:

    gem 'miniproxy'

Configure Capybara (via Chrome and Selenium) to route all requests through the server (`spec/support/capybara_driver.rb`):

    chrome_options = Selenium::WebDriver::Chrome::Options.new
    chrome_options.add_argument("--proxy-server=#{MiniProxy::Server.host}:#{MiniProxy::Server.port}")
    chrome_options.add_argument("--ignore-certificate-errors") # Required to test HTTPS

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
    end

This configuration will not work in conjunction with `--headless`, which causes chrome to fetch its configuration
from another source and silently ignore command line parameters. For details, see:
https://groups.google.com/a/chromium.org/forum/#!topic/headless-dev/eiudRsYdc3A

Make sure that RSpec resets the server after each test, and stops the server when the suite is finished (`spec/support/mini_proxy.rb`):

```ruby
require "miniproxy"

RSpec.configure do |config|
  config.before(:each, type: :feature) do
    # Ignore any requests made between specs
    MiniProxy::Server.ignore_all_requests
  end

  config.after(:each, type: :feature) do
    MiniProxy::Server.reset
  end

  config.after(:suite) do
    MiniProxy::Server.stop
  end
end
```

In your specs, to stub a request:

```ruby
MiniProxy::Server.stub_request(method: "POST", url: /example.com/, response: {
  headers: { "Foo" => "bar" },
  code: 200,
  body: "hello",
})
```

## Developing

Pull requests are welcome, we try our best to stick with [semver](https://semver.org/), avoid breaking changes to the API whenever possible.

Run the unit tests:

    bundle exec rspec spec/lib

Integration tests use capybara/selenium/firefox. So you'll need a modern version of Firefox and Geckodriver on your system PATH. They can be run like so:

    bundle exec rspec spec/integration

Alternatively you can just rely on CI to run the integration tests.

And of course, to run all the tests:

    bundle exec rspec


## Alternatives

- [Puffing Billy](https://github.com/oesmith/puffing-billy) - MiniProxy's more capable and more complex cousin
- [EvilProxy](https://github.com/bbtfr/evil-proxy) - Lighter weight than Puffing Billy, with a focus on HTTPS MITM support

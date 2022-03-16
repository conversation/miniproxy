# MiniProxy [![Build Status](https://travis-ci.org/conversation/miniproxy.svg?branch=master)](https://travis-ci.org/conversation/miniproxy)

A small stubbable proxy server for testing HTTP(S) interactions.

## Supported Versions

* Ruby 2.7, 3.0, 3.1.

## Getting Started

In your Gemfile:

```ruby
gem 'miniproxy'
```

Configure Capybara (via Chrome and Selenium) to route all requests through the server (`spec/support/capybara_driver.rb`):

```ruby
chrome_options = Selenium::WebDriver::Chrome::Options.new
chrome_options.add_argument("--proxy-server=#{MiniProxy.host}:#{MiniProxy.port}")
chrome_options.add_argument("--ignore-certificate-errors") # Required to test HTTPS

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: chrome_options)
end
```

This configuration will not work in conjunction with `--headless`, which causes chrome to fetch its configuration
from another source and silently ignore command line parameters. For details, see:
https://groups.google.com/a/chromium.org/forum/#!topic/headless-dev/eiudRsYdc3A

Make sure that RSpec resets the server after each test, and stops the server when the suite is finished (`spec/support/mini_proxy.rb`):

```ruby
require "miniproxy"

RSpec.configure do |config|
  config.before :each, type: :feature do
    MiniProxy.reset
  end

  config.after :each, type: :feature do
    # Ignore any requests made between specs
    MiniProxy.ignore_all_requests
  end

  config.after :suite do
    MiniProxy.stop
  end
end
```

In your specs, to stub a request:

```ruby
MiniProxy.stub_request(method: "POST", url: /example.com/, response: {
  headers: { "Foo" => "bar" },
  code: 200,
  body: "hello",
})
```

The default behaviour is to block the request, display a warning and return an empty 200 response.

To allow unstubbed requests to hit external servers, you can use a driver configured without using MiniProxy as a proxy server. However, this is not recommended as you will almost certainly have unreliable tests.

## Allowed Hosts

MiniProxy allows requests from the `127.0.0.1` and `localhost` by default.

If your test suite runs at a different address, you can configure a custom host using the `MiniProxy.host` option. Example:

```ruby
MiniProxy.host = "95.124.236.242"
```

With this configuration, MiniProxy will allow all requests coming from the configured host.

You also can permit specific requests to pass through the proxy:

```ruby
MiniProxy.allow_request(method: "GET", url: /example.com/)
```

This implicitly allows CONNECT requests for 'example.com' to permit HTTPS.

## Developing

Pull requests are welcome, we try our best to stick with [semver](https://semver.org/), avoid breaking changes to the API whenever possible.

Run the unit tests:

```
bundle exec rspec spec/lib
```

Integration tests use capybara/selenium/firefox. So you'll need a modern version of Firefox and Geckodriver on your system PATH. They can be run like so:

```
bundle exec rspec spec/integration
```

Alternatively you can just rely on CI to run the integration tests.

And of course, to run all the tests:

```
bundle exec rspec
```

## Alternatives

- [Puffing Billy](https://github.com/oesmith/puffing-billy) - MiniProxy's more capable and more complex cousin
- [EvilProxy](https://github.com/bbtfr/evil-proxy) - Lighter weight than Puffing Billy, with a focus on HTTPS MITM support

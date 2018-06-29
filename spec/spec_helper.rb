require "miniproxy"

RSpec.configure do |config|
  config.after(:suite) { MiniProxy.stop }
end

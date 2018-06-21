require "miniproxy/server"

RSpec.configure do |config|
  config.after(:suite) { MiniProxy::Server.stop }
end

require_relative "./proxy/mini_proxy"

RSpec.configure do |config|
  config.after :each, type: :feature do
    MiniProxy::Server.reset
  end

  config.after :suite do
    MiniProxy::Server.stop
  end
end

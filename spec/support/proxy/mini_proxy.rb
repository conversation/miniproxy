require "drb"
require "singleton"
require "timeout"
require_relative "./remote"

module MiniProxy
  ALLOWED_HOSTS = ["127.0.0.1", "localhost"]

  # MiniProxy server singleton, used as a facade to boot the ProxyServer
  #
  class Server
    include Singleton

    attr_reader :proxy, :fake_server, :port

    def self.reset
      instance.remote.clear
    end

    def self.stop
      instance.remote.stop
    end

    def self.port
      instance.remote.port
    end

    def self.host
      ENV.fetch("MINI_PROXY_HOST", "127.0.0.1")
    end

    def self.stub_request(method:, url:, response: {})
      instance.remote.stub_request(method: method, url: url, response: response)
    end

    def remote
      Timeout.timeout(5) do
        begin
          remote = DRbObject.new(nil, Remote.server)

          until remote.started?
            sleep 0.01
          end

          remote
        rescue
          retry
        end
      end
    end
  end
end

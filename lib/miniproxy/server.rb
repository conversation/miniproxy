require "drb"
require "timeout"
require "miniproxy/remote"

module MiniProxy
  # Provides an interface to communicate with the remote
  # server. Any command given with this interface will start
  # the server if it hasn't started already
  #
  class Server
    DRB_SERVICE_TIMEOUT = 5

    def self.reset
      remote.clear
    end

    def self.stop
      remote.stop if Remote.drb_process_alive?
    end

    def self.port
      remote.port
    end

    def self.host
      "127.0.0.1"
    end

    def self.stub_request(method:, url:, response: {})
      remote.stub_request(method: method, url: url, response: response)
    end

    private_class_method def self.remote
      Timeout.timeout(DRB_SERVICE_TIMEOUT) do
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

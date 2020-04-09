require "drb"
require "timeout"
require "miniproxy/remote"

module MiniProxy
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
    @host || "127.0.0.1"
  end

  def self.host=(host)
    @host = host
  end

  def self.ignore_all_requests
    reset

    %w(GET POST PUT PATCH DELETE).each do |method|
      stub_request(method: method, url: /.*/)
    end
  end

  def self.stub_request(method:, url:, response: {})
    remote.stub_request(method: method, url: url, response: response)
  end

  def self.allow_request(method:, url:)
    remote.allow_request(method: method, url: url)
  end

  private_class_method def self.remote
    Timeout.timeout(DRB_SERVICE_TIMEOUT) do
      begin
        remote = DRbObject.new(nil, Remote.server(self.host))

        until remote.started?
          sleep 0.01
        end

        remote.drain_messages.each(&method(:puts))

        remote
      rescue
        retry
      end
    end
  end
end

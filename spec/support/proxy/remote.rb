require_relative "./stub"
require_relative "./proxy_server"
require_relative "./fake_ssl_server"

module MiniProxy
  # Controls the remote DRb service, which provides a communcation mechanism
  #
  class Remote
    SERVER_DYNAMIC_PORT_RANGE = (12345..32768).to_a.freeze

    def self.pid
      @pid
    end

    def self.drb_process_alive?
      pid && Process.kill(0, pid) == 1
    rescue Errno::ESRCH
      false
    end

    def self.server
      @unix_socket_uri ||= begin
        tempfile = Tempfile.new("mini_proxy")
        socket_path = tempfile.path
        tempfile.close!
        "drbunix:///#{socket_path}"
      end

      return @unix_socket_uri if drb_process_alive?

      @pid = fork do
        remote = Remote.new

        Timeout.timeout(10) do
          begin
            fake_server_port = SERVER_DYNAMIC_PORT_RANGE.sample
            fake_server = FakeSSLServer.new(
              Port: fake_server_port,
              MockHandlerCallback: remote.method(:handler),
            )
            Thread.new { fake_server.start }
          rescue Errno::EADDRINUSE
            retry
          end

          begin
            remote.port = ENV["MINI_PROXY_PORT"] || SERVER_DYNAMIC_PORT_RANGE.sample
            proxy = MiniProxy::ProxyServer.new(
              Port: remote.port,
              FakeServerPort: fake_server_port,
              MockHandlerCallback: remote.method(:handler),
            )
            Thread.new { proxy.start }
          rescue Errno::EADDRINUSE
            retry
          end
        end

        DRb.start_service(@unix_socket_uri, remote)
        DRb.thread.join

        Process.exit!
      end

      Process.detach(@pid)
      @unix_socket_uri
    end

    def handler(req, res)
      if (request = @stubs.detect { |mock_request| mock_request.match?(req) })
        # puts "request detected: #{req.inspect}"
        response = request.response
        res.status = response.code
        response.headers.each { |key, value| res[key] = value }
        res.body = response.body
      else
        res.status = 200
        res.body = ""
        STDOUT.puts "WARN: external request to #{req.host}#{req.path} not mocked"
      end
    end

    def stub_request(method:, url:, response:)
      response = MiniProxy::Stub::Response.new(headers: response[:headers], body: response[:body])
      request = MiniProxy::Stub::Request.new(method: method, url: url, response: response)
      @stubs.push(request)
    end

    def port
      @port
    end

    def port=(value)
      @port = value
    end

    def stop
      DRb.stop_service
    end

    def clear
      @stubs.clear
    end

    def started?
      current_server = DRb.current_server()
      current_server && current_server.alive?
    end

    private

    def initialize
      @stubs = []
    end
  end
end

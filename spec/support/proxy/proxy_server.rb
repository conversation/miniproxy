require "webrick/httpproxy"

module MiniProxy
  # MiniProxy server, which boots a WEBrick proxy server
  #
  class ProxyServer < WEBrick::HTTPProxyServer
    attr_accessor :requests

    def initialize(config = {}, default = WEBrick::Config::HTTP)
      config = config.merge({
        Logger: WEBrick::Log.new(nil, 0), # silence logging
        AccessLog: [], # silence logging
      })

      super(config, default)
    end

    def do_PUT(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.put(path, req.body || "", header)
      end
    end

    def do_DELETE(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.delete(path, header)
      end
    end

    def do_PATCH(req, res)
      perform_proxy_request(req, res) do |http, path, header|
        http.patch(path, req.body || "", header)
      end
    end

    def service(req, res)
      if ALLOWED_HOSTS.include?(req.host)
        super(req, res)
      else
        if req.request_method == "CONNECT"
          # If something is trying to initiate an SSL connection, rewrite
          # the URI to point to our fake server.
          req.instance_variable_set(:@unparsed_uri, "localhost:#{self.config[:FakeServerPort]}")
          super(req, res)
        else
          # Otherwise, call our handler to respond with an appropriate
          # mock for the request.
          self.config[:MockHandlerCallback].call(req, res)
        end
      end
    end
  end
end

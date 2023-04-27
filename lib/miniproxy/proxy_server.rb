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
      perform_proxy_request(req, res, Net::HTTP::Put, req.body_reader)
    end

    def do_DELETE(req, res)
      perform_proxy_request(req, res, Net::HTTP::Delete)
    end

    def do_PATCH(req, res)
      perform_proxy_request(req, res, Net::HTTP::Patch, req.body_reader)
    end

    def service(req, res)
      if self.config[:AllowedRequestCheck].call(req)
        super(req, res)
      else
        if req.request_method == "CONNECT"
          is_ssl = req.unparsed_uri.include?(":443")

          # If something is trying to initiate an SSL connection, rewrite
          # the URI to point to our fake server so we can stub SSL requests.
          if is_ssl
            req.instance_variable_set(:@unparsed_uri, "localhost:#{self.config[:FakeServerPort]}")
          end

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

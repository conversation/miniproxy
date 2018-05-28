require "singleton"
require "webrick/httpproxy"

module MiniProxy
  ALLOWED_HOSTS = Regexp.union("127.0.0.1", "localhost")
  SERVER_HOST = ENV.fetch("MINI_PROXY_HOST", "127.0.0.1")
  SERVER_PORT = ENV.fetch("MINI_PROXY_PORT", "8888")

  module Stub
    class Request
      attr_reader :response

      # @param [String] method
      # @param [Regexp, String] url
      # @param [MiniProxy::Response] response
      def initialize(method:, url:, response:)
        @method = method
        @response = response
        @url = url
      end

      # @param [WEBrick::HTTPRequest] http_request
      def match?(http_request)
        http_request.request_method == @method && http_request.unparsed_uri.match?(@url)
      end
    end

    class Response
      def initialize(headers:, body:)
        @body = body
        @headers = headers
      end

      def body
        @body.presence || ""
      end

      def code
        200
      end

      def headers
        @headers.presence || { "Content-Type" => "text/html" }
      end
    end
  end

  class ProxyServer < WEBrick::HTTPProxyServer
    attr_accessor :requests

    def initialize(config = {}, default = WEBrick::Config::HTTP)
      @requests = []
      super(config, default)
    end

    # @param [WEBrick::HTTPRequest] req
    # @param [WEBrick::HTTPResponse] res
    def service(req, res)
      # if req.unparsed_uri.match?("theconversation-temp-test")
      #   binding.pry
      #   temp = super(req, res)
      #   binding.pry
      # end

      # TODO: FAILING? WHAT TO RETURN?
      if (request = @requests.detect { |request| request.match?(req) })
        if req.request_method == "CONNECT"
          ua = Thread.current[:WEBrickSocket]  # User-Agent
          # res.status = WEBrick::HTTPStatus::RC_OK
          # res.send_response(ua)
          # res.body = "CONNECT HTTP/1.0" + WEBrick::CRLF + WEBrick::CRLF
          #
          # # Should clear request-line not to send the response twice.
          # # see: HTTPServer#run
          # req.parse(NullReader) rescue nil
          #
          # # binding.pry
          #


          # do_CONNECT(req, res)
          # "HTTP/1.1 200 Connection established\r\n\r\n"
          # binding.pry
          #

          # binding.pry

          temp = <<-STRING
GET /sockjs-node/936/rnubhg5k/websocket HTTP/1.1
Host: localhost:8080
Connection: Upgrade
Pragma: no-cache
Cache-Control: no-cache
Upgrade: websocket
Origin: http://127.0.0.1:56091
Sec-WebSocket-Version: 13
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.9
Sec-WebSocket-Key: RAR+YMI1nh9EbeIT/Vyf/w==
Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits
          STRING
          ua.syswrite(temp)
          res.status = 200
          res.send_response(ua)

          return
        end

        response = request.response

        res.status = response.code
        response.headers.each { |key, value| res[key] = value }
        res.body = response.body

        return
      end

      # Default response: 400 (Bad Request)
      unless req.unparsed_uri.match?(MiniProxy::ALLOWED_HOSTS)
        res.status = 400
        return
      end

      super(req, res)
    end

    def stack_request(method:, url:, response:)
      # TODO: break apart request/response objects
      response = MiniProxy::Stub::Response.new(headers: response[:headers], body: response[:body])
      request = MiniProxy::Stub::Request.new(method: method, url: url, response: response)
      @requests << request
    end

    def empty_request_stack
      @requests = []
    end
  end

  class Server
    include Singleton

    attr_reader :proxy

    def self.reset
      instance.proxy.empty_request_stack
    end

    def self.start
      instance
    end

    def self.stub_request(method:, url:, response: {})
      instance.proxy.stack_request(method: method, url: url, response: response)
    end

    def initialize
      @proxy = MiniProxy::ProxyServer.new(Port: MiniProxy::SERVER_PORT)
      @thread = Thread.new { @proxy.start }
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { MiniProxy::Server.start }
  config.after(:each) { puts MiniProxy::Server.reset }
end

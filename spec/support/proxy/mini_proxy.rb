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

  class ContentHandler
    attr_accessor :requests

    def initialize
      @requests = []
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

    def call(req, res)
      if (request = @requests.detect { |request| request.match?(req) })
        response = request.response

        res.status = response.code
        response.headers.each { |key, value| res[key] = value }
        res.body = response.body
      end
    end
  end

  class ProxyServer < WEBrick::HTTPProxyServer
    # @param [WEBrick::HTTPRequest] req
    # @param [WEBrick::HTTPResponse] res
    def service(req, res)
      # Default response: 400 (Bad Request)
      unless req.unparsed_uri.match?(MiniProxy::ALLOWED_HOSTS)
        res.status = 400
        return ""
      end

      super(req, res)
    end
  end

  class Server
    attr_reader :handler

    private_class_method :new

    def self.start
      @server ||= new
    end

    def self.stub_request(method:, url:, response: {})
      @server.handler.stack_request(method: method, url: url, response: response)
    end

    def self.reset
      @server.handler.empty_request_stack
    end

    def initialize
      @handler = MiniProxy::ContentHandler.new
      @thread = Thread.new do
        proxy = MiniProxy::ProxyServer.new(Port: MiniProxy::SERVER_PORT, ProxyContentHandler: @handler)
        proxy.start
      end
    end
  end
end

MiniProxy::Server.start

RSpec.configure do |config|
  config.after { puts MiniProxy::Server.reset }
end

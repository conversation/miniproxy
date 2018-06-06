require "singleton"
require "timeout"
require "webrick/httpproxy"
require "webrick/https" # THIS IS KEY

module MiniProxy
  ALLOWED_HOSTS = Regexp.union("127.0.0.1", "localhost")

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

    # if we receive an SSL request, hand it off to our fake server, which is ready
    # and waiting to respond with mocks!
    def do_CONNECT(req, res)
      req.instance_variable_set(:@unparsed_uri, "localhost:#{self.config[:FakeServerPort]}")
      super(req, res)
    end

    def service(req, res)
      if (request = @requests.detect { |request| request.match?(req) })
        response = request.response
        res.status = response.code
        response.headers.each { |key, value| res[key] = value }
        res.body = response.body
      else
        super(req, res)
      end
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

  class FakeServer < WEBrick::HTTPProxyServer
    # TODO: respond with mocks?
    def service(req, res)
      res.status = 200
      res.body = ""
      STDOUT.puts "WARN: request to #{req.host}#{req.path} not mocked"
    end
  end

  class Server
    SERVER_DYNAMIC_PORT_RANGE = (12345..32768).to_a.freeze

    include Singleton

    attr_reader :proxy, :port

    def self.reset
      instance.proxy.empty_request_stack
    end

    def self.start
      instance
    end

    def self.port
      instance.port
    end

    def self.host
      ENV.fetch("MINI_PROXY_HOST", "127.0.0.1")
    end

    def self.stub_request(method:, url:, response: {})
      instance.proxy.stack_request(method: method, url: url, response: response)
    end

    def initialize
      ssl = Fauthentic.generate

      Timeout::timeout(10) do
        begin
          @fake_server_port = SERVER_DYNAMIC_PORT_RANGE.sample
          @fake_server = FakeServer.new(
            Port: @fake_server_port,
            Logger: WEBrick::Log.new(nil, 0), # silence logging
            AccessLog: [], # silence logging
            SSLEnable: true,
            SSLCertificate: OpenSSL::X509::Certificate.new(ssl.cert.to_pem),
            SSLPrivateKey: OpenSSL::PKey::RSA.new(ssl.key.to_s),
            SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
            SSLCertName: [["CN", WEBrick::Utils::getservername]],
          )
          @thread = Thread.new { @fake_server.start }
        rescue
          retry
        end

        begin
          @port = ENV["MINI_PROXY_PORT"] || SERVER_DYNAMIC_PORT_RANGE.sample
          @proxy = MiniProxy::ProxyServer.new(
            Port: @port,
            FakeServerPort: @fake_server_port,
            Logger: WEBrick::Log.new(nil, 0), # silence logging
            AccessLog: [], # silence logging
          )
          @thread = Thread.new { @proxy.start }
        rescue Errno::EADDRINUSE
          retry
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { MiniProxy::Server.start }
  config.after(:each) { puts MiniProxy::Server.reset }
end

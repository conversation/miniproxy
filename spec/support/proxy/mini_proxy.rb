require "http"
require "rack"

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

      # @param [Rack::Request] rack_request
      def match?(rack_request)
        rack_request.request_method == @method && rack_request.url.match?(@url)
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

  class Rack
    attr_accessor :requests

    def initialize
      @requests = []
    end

    def stack_request(method:, url:, response:)
      response = MiniProxy::Stub::Response.new(headers: response[:headers], body: response[:body])
      request = MiniProxy::Stub::Request.new(method: method, url: url, response: response)
      @requests << request
    end

    def empty_request_stack
      @requests = []
    end

    def call(env)
      rack_request = ::Rack::Request.new(env)
      rack_response = ::Rack::Response.new([], 400) # Default response: 400 (Bad Request)

      # Match stubbed request
      if (request = @requests.detect { |request| request.match?(rack_request) })
        response = request.response

        response.headers.each do |key, value|
          rack_response.set_header(key, value)
        end

        rack_response.status = response.code
        rack_response.body = [response.to_s]

        return rack_response.finish
      end

      # Fetch allowed hosts
      if rack_request.host.match?(MiniProxy::ALLOWED_HOSTS)
        # - [x] Handle form submits
        # - [ ] Handle file uploads
        options = case rack_request.request_method
        when "POST"
          { body: rack_request.params.to_query }
        else
          {}
        end

        response = HTTP
          .cookies(rack_request.cookies)
          .request(rack_request.request_method, rack_request.url, options)

        # Merge cookies that were set on the proxy server response
        response.cookies.each do |cookie|
          rack_response.set_cookie(cookie.name, cookie.value)
        end

        response.headers.each do |key, value|
          rack_response.set_header(key, value)
        end

        rack_response.status = response.code
        rack_response.body = [response.to_s]
      end

      rack_response.finish
    end
  end

  class Server
    attr_reader :mini_proxy

    private_class_method :new

    def self.start
      @server ||= new
    end

    def self.stub_request(method:, url:, response: {})
      @server.mini_proxy.stack_request(method: method, url: url, response: response)
    end

    def self.reset
      @server.mini_proxy.empty_request_stack
    end

    def initialize
      @mini_proxy = MiniProxy::Rack.new
      @thread = Thread.new do
        ::Rack::Handler::WEBrick.run(@mini_proxy, {
          Host: ENV.fetch("MINI_PROXY_HOST", "127.0.0.1"),
          Port: ENV.fetch("MINI_PROXY_PORT", "8888"),
        })
      end
    end
  end
end

MiniProxy::Server.start

RSpec.configure do |config|
  config.after { puts MiniProxy::Server.reset }
end

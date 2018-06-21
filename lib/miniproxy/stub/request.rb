module MiniProxy
  module Stub
    # MiniProxy stub request to match and stub external URLs with a stubbed response
    #
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
        request_uri = http_request.host + http_request.path
        http_request.request_method == @method && request_uri.match?(@url)
      end
    end
  end
end

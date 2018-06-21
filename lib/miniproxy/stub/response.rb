module MiniProxy
  module Stub
    # MiniProxy stub response, so stubbed requests can return a custom response
    #
    class Response
      def initialize(headers:, body:)
        @body = body
        @headers = headers
      end

      def body
        @body || ""
      end

      def code
        200
      end

      def headers
        @headers || { "Content-Type" => "text/html" }
      end
    end
  end
end

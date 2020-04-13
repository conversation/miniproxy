require "webrick/https" # This is required to create a HTTPS server
# https://ruby-doc.org/stdlib-2.0.0/libdoc/webrick/rdoc/WEBrick.html#module-WEBrick-label-HTTPS

module MiniProxy
  # MiniProxy fake SSL enabled server, which receives relayed requests from the ProxyServer
  #
  class FakeSSLServer < WEBrick::HTTPServer
    def initialize(config = {}, default = WEBrick::Config::HTTP)
      config = config.merge({
        Logger: WEBrick::Log.new(nil, 0), # silence logging
        AccessLog: [], # silence logging
        SSLEnable: true,
        SSLCertificate: OpenSSL::X509::Certificate.new(certificate_file("cert.pem")),
        SSLPrivateKey: OpenSSL::PKey::RSA.new(certificate_file("cert.key")),
        SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
      })

      super(config, default)
    end

    def service(req, res)
      if self.config[:AllowedRequestCheck].call(req)
        super(req, res)
      else
        self.config[:MockHandlerCallback].call(req, res)
      end
    end

    private

    def certificate_file(filename)
      filename = File.join( File.dirname(__FILE__), "../../ssl/#{filename}")
      File.open(filename).read
    end
  end
end

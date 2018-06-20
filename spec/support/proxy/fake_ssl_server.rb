require "fauthentic"
require "webrick/https" # THIS IS KEY

module MiniProxy
  # MiniProxy fake SSL enabled server, which receives relayed requests from the ProxyServer
  #
  class FakeSSLServer < WEBrick::HTTPServer
    ALLOWED_HOSTS = ["127.0.0.1", "localhost"].freeze

    def initialize(config = {}, default = WEBrick::Config::HTTP)
      ssl = Fauthentic.generate

      config = config.merge({
        Logger: WEBrick::Log.new(nil, 0), # silence logging
        AccessLog: [], # silence logging
        SSLEnable: true,
        SSLCertificate: OpenSSL::X509::Certificate.new(ssl.cert.to_pem),
        SSLPrivateKey: OpenSSL::PKey::RSA.new(ssl.key.to_s),
        SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
        SSLCertName: [["CN", WEBrick::Utils.getservername]],
      })

      super(config, default)
    end

    def service(req, res)
      if ALLOWED_HOSTS.include?(req.host)
        super(req, res)
      else
        self.config[:MockHandlerCallback].call(req, res)
      end
    end
  end
end

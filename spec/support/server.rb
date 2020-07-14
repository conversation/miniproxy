class EchoServlet < WEBrick::HTTPServlet::AbstractServlet
  def echo(req, res)
    res.body = "#{req.request_method} #{req.path} #{req.body}"
  end

  [:GET, :POST, :PUT, :PATCH, :DELETE].each do |m|
    alias_method :"do_#{m}", :echo
  end
end

def with_proxied_echo_server(config={}, &block)
  start_server(WEBrick::HTTPServer) do |origin_server, origin_addr, origin_port|
    origin_server.mount '/', EchoServlet

    start_server(MiniProxy::ProxyServer, {
      ProxyURI: URI.parse("http://#{origin_addr}:#{origin_port}"),
      AllowedRequestCheck: ->(req) { true },
      MockHandlerCallback: ->(req, res) { double(:handler) },
    }.merge(config)) do |proxy_sever, proxy_addr, proxy_port|
      yield Net::HTTP.new(origin_addr, origin_port, proxy_addr, proxy_port)
    end
  end
end

# The following methods are derived from
# https://github.com/ruby/webrick/blob/4938ec3fae3ce32cceb685f6b8efff8926340c09/test/webrick/test_httpproxy.rb

def start_server(klass, config={}, &block)
  server = klass.new({
    ServerType: Thread,
    BindAddress: "127.0.0.1",
    Port: 0,
    Logger: WEBrick::Log.new([], WEBrick::BasicLog::WARN),
    AccessLog: [],
  }.merge(config))

  server_thread = server.start

  addr = server.listeners[0].addr

  client_thread = Thread.new {
    begin
      block.yield([server, addr[3], addr[1]])
    ensure
      server.shutdown
    end
  }

  assert_join_threads([client_thread, server_thread])
end

def assert_join_threads(threads, message = nil)
  errs = []
  values = []
  while th = threads.shift
    begin
      values << th.value
    rescue Exception
      errs << [th, $!]
      th = nil
    end
  end
  values
ensure
  if th&.alive?
    th.raise(Timeout::Error.new)
    th.join rescue errs << [th, $!]
  end
  if !errs.empty?
    msg = "exceptions on #{errs.length} threads:\n" +
      errs.map {|t, err|
      "#{t.inspect}:\n" +
        err.full_message(highlight: false, order: :top)
    }.join("\n---\n")
    if message
      msg = "#{message}\n#{msg}"
    end
    expect(msg).to eq("")
  end
end

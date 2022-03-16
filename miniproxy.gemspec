lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'miniproxy/version'

Gem::Specification.new do |s|
  s.name = 'miniproxy'
  s.version = MiniProxy::VERSION
  s.authors = ['The Conversation Dev Team']

  s.summary = 'Easily stub external requests for your browser tests.'
  s.description = 'A tool which allows you to easily stub requests to external sites for your browser tests.'
  s.homepage = 'https://github.com/conversation/miniproxy'
  s.license = 'MIT'

  s.files = `git ls-files -- lib/* ssl/*`.split("\n")

  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'capybara', '~> 3.36'
  s.add_development_dependency 'selenium-webdriver', '~> 3.142'
end

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'miniproxy/version'

Gem::Specification.new do |s|
  s.name = 'miniproxy'
  s.version = MiniProxy::VERSION
  s.summary = 'Stub requests for browser tests'
  s.authors = ["x"]

  s.files = `git ls-files -- lib/*`.split("\n")

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'selenium-webdriver'
end

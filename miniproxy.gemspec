spec = Gem::Specification.new do |s|
  s.name = 'miniproxy'
  s.version = '0.0.0'
  s.summary = 'Stub requests for browser tests'
  s.authors = ["x"]

  s.files = `git ls-files -- lib/*`.split("\n")

  s.add_development_dependency 'rspec'
end

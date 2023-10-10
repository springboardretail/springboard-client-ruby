Gem::Specification.new do |s|
  s.name              = 'heartland-retail'
  s.version           = '5.0.1'
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Jay Stotz', 'Derek Stotz']
  s.summary           = 'Heartland Retail API client library'

  s.add_runtime_dependency 'faraday', '~> 1.0'
  s.add_runtime_dependency 'json', '>= 1.7.4'
  s.add_runtime_dependency 'hashie'

  s.files         = `git ls-files`.split("\n")

  s.require_path = 'lib'
end

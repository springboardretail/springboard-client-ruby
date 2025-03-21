Gem::Specification.new do |s|
  s.name              = 'heartland-retail'
  s.version           = '5.2.0'
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Jay Stotz', 'Derek Stotz']
  s.summary           = 'Heartland Retail API client library'

  s.add_runtime_dependency 'faraday', '2.12.2'
  s.add_runtime_dependency 'json', '>= 2.7.1'
  s.add_runtime_dependency 'hashie', '4.1.0'

  s.files         = `git ls-files`.split("\n")

  s.require_path = 'lib'
end

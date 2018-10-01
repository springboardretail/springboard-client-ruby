Gem::Specification.new do |s|
  s.name              = 'springboard-retail'
  s.version           = '4.3.0'
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Jay Stotz']
  s.summary           = 'Springboard Retail API client library'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency 'faraday', '0.11'
  s.add_runtime_dependency 'faraday-cookie_jar', '0.0.6'
  s.add_runtime_dependency 'json', '>= 1.7.4'
  s.add_runtime_dependency 'hashie'

  s.files         = `git ls-files`.split("\n")

  s.require_path = 'lib'
end

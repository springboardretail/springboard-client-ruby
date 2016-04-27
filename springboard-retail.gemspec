Gem::Specification.new do |s|
  s.name              = 'springboard-retail'
  s.version           = '4.0.1'
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Jay Stotz']
  s.summary           = 'Springboard Retail API client library'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency 'patron', '>= 0.5.0'
  s.add_runtime_dependency 'addressable', '~> 2.2.8'
  s.add_runtime_dependency 'json', '>= 1.7.4'
  s.add_runtime_dependency 'hashie'

  s.files         = `git ls-files`.split("\n")

  s.require_path = 'lib'
end

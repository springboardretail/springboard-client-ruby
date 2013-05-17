Gem::Specification.new do |s|
  s.name              = "sagamore-client"
  s.version           = "3.0.1"
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Sagamore"]
  s.summary           = "Sagamore client library"

  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_runtime_dependency 'patron', '~> 0.4.18'
  s.add_runtime_dependency 'addressable', '~> 2.2.8'
  s.add_runtime_dependency 'json', '~> 1.7.4'
  s.add_runtime_dependency 'hashie'

  s.files         = `git ls-files`.split("\n")
  
  s.require_path = 'lib'
end



Gem::Specification.new do |s|
  s.name              = "sagamore-client"
  s.version           = "3.0.0pre"
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Sagamore"]
  s.summary           = "Sagamore client library"

  s.required_rubygems_version = ">= 1.3.6"
  
  s.add_runtime_dependency 'patron'
  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'hashie'

  s.files         = `git ls-files`.split("\n")
  
  s.require_path = 'lib'
end



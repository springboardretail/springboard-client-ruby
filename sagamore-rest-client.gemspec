Gem::Specification.new do |s|
  s.name = "sagamore-rest-client"
  s.version = "2.0.1"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Sagamore"]
  s.summary = "REST client for use in Sagamore client applications"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency("rest-client")
  s.add_dependency("json", '>= 1.4.1')

  s.files = `git ls-files`.split("\n")

  s.require_path = 'lib'
end


require 'rubygems'
require 'rake'
require 'rake/gempackagetask'

task :install => [:package] do
  `gem install pkg/#{PKG_FILE_NAME}.gem`
end

spec = Gem::Specification.new do |s|
  s.name = "slingshot-rest-client"
  s.version = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.6'
  s.summary = "REST client for use in Slingshot client applications"
  s.files = FileList["{lib}/**/*"].to_a
  s.add_dependency("rest-client")
  s.add_dependency("activesupport")
  s.add_dependency("json", '>= 1.1.3')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
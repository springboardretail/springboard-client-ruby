require 'bundler/setup'
Bundler.require(:default, :development)

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :console do
  require 'sagamore/client'
  CLIENT = Sagamore::Client.new \
    ENV['URI'],
    :username => ENV['USER'],
    :password => ENV['PASSWORD']
  Pry.start
end

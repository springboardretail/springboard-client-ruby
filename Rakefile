require 'bundler/setup'
require 'bundler/gem_tasks'
Bundler.require(:default, :development)

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc "Start a console with a Springboard::Client instance"
task :console do
  require 'springboard/client'
  CLIENT = Springboard::Client.new(ENV['URI'])
  CLIENT.auth :username => ENV['USER'], :password => ENV['PASSWORD']
  Pry.start
end

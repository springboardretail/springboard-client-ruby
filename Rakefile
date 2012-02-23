require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

$: << File.join(File.dirname(__FILE__), 'lib')

# Include all files in lib/rake
Dir.glob('./tasks/*.rake').each {|f| load File.join(File.dirname(__FILE__), f)}


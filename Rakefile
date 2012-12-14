require 'rubygems'
require 'rspec/core/rake_task'
require 'bundler'

desc 'Run specs'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

Bundler::GemHelper.install_tasks

# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twig/homepage'
require 'twig/version'

Gem::Specification.new do |spec|
  spec.name          = 'twig'
  spec.version       = Twig::VERSION
  spec.authors       = ['Ron DeVera']
  spec.email         = ["hello@rondevera.com"]
  spec.homepage      = Twig::HOMEPAGE
  spec.summary       = %{Your personal Git branch assistant.}
  spec.description   =
    'Twig is your personal Git branch assistant. It\'s a command-line tool ' <<
    'for tracking progress on your branches, remembering ticket ids for ' <<
    'each branch, and more. Twig supports subcommands for managing branches ' <<
    'however you want.'
  spec.post_install_message =
    "\n**************************************************************" <<
    "\n*                                                            *" <<
    "\n* Welcome to Twig!                                           *" <<
    "\n*                                                            *" <<
    "\n* To get started, run `twig` to list your Git branches, and  *" <<
    "\n* `twig --help` for more info.                               *" <<
    "\n*                                                            *" <<
    "\n**************************************************************" <<
    "\n\n"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}).map { |file| File.basename(file) }
  spec.require_paths = ['lib']
  spec.test_files    = spec.files.grep(%r{^spec/})

  spec.required_ruby_version = '>= 1.8.7'
  spec.add_runtime_dependency     'json',     '~> 1.7.5'
  spec.add_runtime_dependency     'launchy',  '~> 2.3.0'
  spec.add_development_dependency 'rake',     '~> 0.9.2'
  spec.add_development_dependency 'rspec',    '~> 2.13.0'
end

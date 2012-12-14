# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twig/version'

Gem::Specification.new do |spec|
  spec.name          = 'twig'
  spec.version       = Twig::VERSION
  spec.date          = '2012-12-13'
  spec.authors       = ['Ron DeVera']
  spec.email         = ["hello@rondevera.com"]
  spec.homepage      = 'https://github.com/rondevera/twig'
  spec.summary       = %{Track progress on your Git branches.}
  spec.description   =
    'Twig is a command-line tool for tracking progress on your Git ' <<
    'branches, remembering ticket ids for each branch, and more. Twig ' <<
    'supports subcommands for managing branches in your own way.'
  spec.post_install_message =
    "\n**************************************************************" <<
    "\n*                                                            *" <<
    "\n* Twig!                                                      *" <<
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
  spec.add_runtime_dependency     'json',  '~> 1.7.5'
  spec.add_development_dependency 'rake',  '~> 0.9.2'
  spec.add_development_dependency 'rspec', '~> 2.11.0'
end

# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'blueprinter/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'blueprinter-rb'
  s.version     = Blueprinter::VERSION
  s.authors     = ['Ritikesh G']
  s.email       = ['ritikeshsisodiya@gmail.com']
  s.homepage    = 'https://github.com/blueprinter-ruby/blueprinter'
  s.summary     = 'Simple Fast Declarative Serialization Library'
  s.description = 'Blueprinter is a JSON Object Presenter for Ruby that takes business objects and breaks' \
                  'them down into simple hashes and serializes them to JSON. It can be used in Rails in place of other' \
                  'serializers (like JBuilder or ActiveModelSerializers). It is designed to be simple, direct, and performant.'
  s.license     = 'MIT'

  s.files = Dir['{lib}/**/*', 'MIT-LICENSE', 'README.md']

  s.required_ruby_version = '>= 2.6.9'

  s.metadata['rubygems_mfa_required'] = 'true'
end

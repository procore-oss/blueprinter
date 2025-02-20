# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'blueprinter/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'blueprinter'
  s.version     = Blueprinter::VERSION
  s.authors     = ['Procore Technologies, Inc.']
  s.email       = ['opensource@procore.com']
  s.homepage    = 'https://github.com/procore-oss/blueprinter'
  s.summary     = 'Simple Fast Declarative Serialization Library'
  s.description = 'Blueprinter is a JSON Object Presenter for Ruby that takes business objects ' \
                  'and breaks them down into simple hashes and serializes them to JSON. ' \
                  'It can be used in Rails in place of other serializers (like JBuilder or ActiveModelSerializers). ' \
                  'It is designed to be simple, direct, and performant.'
  s.license     = 'MIT'
  s.metadata['allowed_push_host'] = 'https://rubygems.org'

  s.files = Dir['{app,config,db,lib}/**/*', 'CHANGELOG.md', 'LICENSE.md', 'Rakefile', 'README.md']

  s.required_ruby_version = '>= 3.0'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_development_dependency 'multi_json', '~> 1.0'
end

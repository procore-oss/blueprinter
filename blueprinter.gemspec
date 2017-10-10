$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "blueprinter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blueprinter"
  s.version     = Blueprinter::VERSION
  s.authors     = ["Adam Hess", "Derek Carter"]
  s.email       = ["adamhess1991@gmail.com"]
  s.homepage    = "https://github.com/procore/blueprinter"
  s.summary     = "Simple Fast Declarative Serialization Library"
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.required_ruby_version = '>= 2.2.2'

  s.add_development_dependency "rails", "~> 5.1.2"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "yard", "~> 0.9.9"

  s.add_runtime_dependency "json"
end

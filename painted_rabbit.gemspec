$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "painted_rabbit/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "painted_rabbit"
  s.version     = PaintedRabbit::VERSION
  s.authors     = ["Adam Hess", "Derek Carter"]
  s.email       = ["adamhess1991@gmail.com"]
  s.homepage    = "https://github.com/procore/painted-rabbit"
  s.summary     = "Simple Fast Declarative Serialization Library"
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_development_dependency "rails", "~> 5.1.2"

  s.add_development_dependency "json"

  s.add_development_dependency "sqlite3"
end

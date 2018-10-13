require 'rdoc/task'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rspec/core/rake_task'

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Blueprinter'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--pattern spec/**/*_spec.rb --warnings'
end

Rake::TestTask.new(:benchmarks) do |t|
  t.libs << 'spec'
  t.pattern = 'spec/benchmarks/**/*_test.rb'
  t.verbose = false
end

task default: :spec

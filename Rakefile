begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'PaintedRabbit'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end






require 'bundler/gem_tasks'

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = Dir['test/**/*_test.rb'].reject do |path|
    path.include?('benchmarks')
  end
  t.verbose = false
end

Rake::TestTask.new(:benchmarks) do |t|
  t.libs << 'test'
  t.pattern = 'test/benchmarks/**/*_test.rb'
  t.verbose = false
end

task default: :test

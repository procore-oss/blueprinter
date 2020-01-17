require 'active_record/railtie' # see https://github.com/rspec/rspec-rails/issues/1690 for vague hints
require 'ammeter/init'
require 'generators/shared'

RSpec.shared_context "generator_destination", :shared_context => :metadata do
  destination File.expand_path("../../tmp", __FILE__)
  before do
    prepare_destination
    FileUtils.cd(File.expand_path("../../tmp", __FILE__)) # force all generator output into .gitignored tmp, don't pollute gem source
  end
  after do
    FileUtils.cd("..")
  end
end

RSpec.shared_context "vehicle_subject", :shared_context => :metadata do
  let (:model) { "vehicle" }
  subject { file('app/blueprints/vehicle_blueprint.rb') }
end

RSpec.shared_context "initializer_subject", :shared_context => :metadata  do
  subject { file('config/initializers/blueprinter.rb') }
end

RSpec.configure do |rspec|
  rspec.include_context "generator_destination", :include_shared => true
  rspec.include_context "vehicle_subject", :include_shared => true
  rspec.include_context "initializer_subject", :include_shared => true
end

require 'spec_helper'

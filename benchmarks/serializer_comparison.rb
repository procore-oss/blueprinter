# frozen_string_literal: true

# Serializer Comparison Benchmark
#
# Compares Blueprinter performance against other Ruby serializers.
# Based on https://github.com/procore-oss/blueprinter/issues/113
#
# Usage: ruby benchmarks/serializer_comparison.rb
#
# Serializers compared:
#   - as_json (baseline)
#   - alba
#   - fast_jsonapi (Netflix, archived)
#   - grape-entity
#   - blueprinter (this gem)
#   - active_model_serializers
#   - roar
#   - panko (C extension)

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'oj'
  gem 'benchmark-ips', require: 'benchmark/ips'
  gem 'kalibera'
  gem 'benchmark-memory', require: 'benchmark/memory'

  gem 'activesupport'

  # https://github.com/okuramasafumi/alba
  gem 'alba'

  # https://github.com/Netflix/fast_jsonapi
  gem 'fast_jsonapi'

  # https://github.com/ruby-grape/grape-entity
  gem 'grape-entity'

  # https://github.com/rails-api/active_model_serializers/tree/0-10-stable
  gem 'active_model_serializers', '~> 0.10.0'

  # https://github.com/trailblazer/roar
  # https://github.com/trailblazer/representable
  gem 'roar'
  gem 'multi_json'

  # https://github.com/yosiat/panko_serializer
  gem 'panko_serializer'
end

require 'active_support'
require 'active_support/core_ext/object'

# Load blueprinter from local lib
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'blueprinter'

# Helper for AMS compatibility
module ModelName
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def model_name
      ActiveModel::Name.new(self)
    end
  end
end

# Define models
Issue = Struct.new(:id, :number, :title, :user, :labels) do
  include ModelName
  alias_method :read_attribute_for_serialization, :send

  def label_ids
    labels.map(&:id)
  end

  def user_id
    user.id
  end
end
User = Struct.new(:id, :login) do
  include ModelName
  alias_method :read_attribute_for_serialization, :send
end
Label = Struct.new(:id, :name, :color) do
  include ModelName
  alias_method :read_attribute_for_serialization, :send
end

# Define serializers
module AlbaSerializer
  class Label
    include Alba::Resource
    attributes :id, :name, :color
  end

  class User
    include Alba::Resource
    attributes :id, :login
  end

  class Issue
    include Alba::Resource
    attributes :id, :number, :title
    many :labels, resource: Label
    one :user, resource: User
  end
end

module FastJsonApi
  class IssueSerializer
    include FastJsonapi::ObjectSerializer

    attributes :number, :title
    has_many :labels
    belongs_to :user
  end

  class LabelSerializer
    include FastJsonapi::ObjectSerializer

    attributes :name, :color
  end

  class UserSerializer
    include FastJsonapi::ObjectSerializer

    attributes :login
  end
end

module GrapeEntity
  class Label < Grape::Entity
    expose :id
    expose :name
    expose :color
  end

  class User < Grape::Entity
    expose :id
    expose :login
  end

  class Issue < Grape::Entity
    expose :id
    expose :number
    expose :title
    expose :labels, using: Label
    expose :user, using: User
  end
end

Blueprinter.configure do |config|
  config.generator = Oj
  config.sort_fields_by = :definition
end

module BluePrint
  class Label < Blueprinter::Base
    identifier :id
    fields :name, :color
  end

  class User < Blueprinter::Base
    identifier :id
    field :login
  end

  class Issue < Blueprinter::Base
    identifier :id
    fields :number, :title
    association :labels, blueprint: Label
    association :user, blueprint: User
  end
end

ActiveModelSerializers.logger = nil
module Ams
  class Label < ActiveModel::Serializer
    attributes :id, :name, :color
  end

  class User < ActiveModel::Serializer
    attributes :id, :login
  end

  class Issue < ActiveModel::Serializer
    attributes :id, :number, :title
    has_many :labels, serializer: Label
    belongs_to :user, serializer: User
  end
end

require 'roar/decorator'
require 'roar/json'
module ROAR
  class IssueRepresenter < Roar::Decorator
    include Roar::JSON

    property :id
    property :number
    property :title

    collection :labels do
      property :id
      property :name
      property :color
    end

    property :user do
      property :id
      property :login
    end
  end
end

module PANKO
  class LabelSerializer < Panko::Serializer
    attributes :id, :name, :color
  end

  class UserSerializer < Panko::Serializer
    attributes :id, :login
  end

  class IssueSerializer < Panko::Serializer
    attributes :id, :number, :title
    has_many :labels, serializer: LabelSerializer
    has_one :user, serializer: UserSerializer
  end
end

# Generate data
users = Array.new(10) { |i| User.new(i, "User #{i}") }
labels = Array.new(4) { |i| Label.new(i, "Label #{i}", 'ffffff') }
issues = Array.new(10_000) { |i| Issue.new(i, i, "Issue #{i}", users.sample, labels.sample(rand(2..4))) }

serializers = [
  {
    name: :as_json,
    serializer: -> { issues.as_json },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :alba,
    serializer: -> { AlbaSerializer::Issue.new(issues).to_h },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :fast_jsonapi,
    serializer: -> { FastJsonApi::IssueSerializer.new(issues, include: [:labels, :user]).serializable_hash },
    output_inspector: ->(output) { output[:data].first }
  },
  {
    name: :grape_entity,
    serializer: -> { GrapeEntity::Issue.represent(issues).as_json },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :blueprinter,
    serializer: -> { BluePrint::Issue.render_as_hash(issues) },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :ams,
    serializer: -> { ActiveModelSerializers::SerializableResource.new(issues, each_serializer: Ams::Issue).as_json },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :roar,
    serializer: -> { ROAR::IssueRepresenter.for_collection.new(issues).as_json },
    output_inspector: ->(output) { output.first }
  },
  {
    name: :panko,
    serializer: -> { Panko::ArraySerializer.new(issues, each_serializer: PANKO::IssueSerializer).as_json },
    output_inspector: ->(output) { output['subjects'].first }
  }
]

# Display output
serializers.each do |s|
  puts "\n#{s[:name]}:\n"
  puts s[:output_inspector].call(s[:serializer].call).inspect
  puts
end

# Run benchmarks
require 'benchmark'
Benchmark.bmbm do |b|
  serializers.each do |s|
    b.report(s[:name], &s[:serializer])
  end
end

%i[ips memory].each do |bench|
  Benchmark.send(bench) do |b|
    b.config(time: 10, warmup: 5, stats: :bootstrap, confidence: 95) if b.respond_to?(:config)

    serializers.each do |s|
      b.report(s[:name], &s[:serializer])
    end

    b.compare!
  end
end

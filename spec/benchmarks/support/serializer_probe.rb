# frozen_string_literal: true

# Measures one serializer configuration in a fresh process and prints the result as one JSON line.
# Run by serializers_test.rb; see that file for why each configuration needs its own process.
#
#   ruby -Ilib -Ispec spec/benchmarks/support/serializer_probe.rb SERIALIZER PAYLOAD ACTIVESUPPORT(0|1)

require 'json'
if ARGV[2] == '1'
  require 'active_support'
  require 'active_support/core_ext/object/json'
end
require 'benchmark_helper'

module SerializerProbe
  extend BenchmarkHelper

  OBJECT_COUNT = 1000
  EPOCH = 1_790_000_000

  # name => configuration applied before anything is rendered
  SERIALIZERS = {
    'json' => ->(_config) {},
    'oj_generate' => lambda do |config|
      require 'oj'
      config.generator = Oj
    end,
    'oj_compat' => lambda do |config|
      require 'oj'
      config.generator = ->(hash) { Oj.dump(hash, mode: :compat) }
      config.method = :call
    end,
    'oj_rails' => lambda do |config|
      require 'oj'
      config.generator = ->(hash) { Oj.dump(hash, mode: :rails) }
      config.method = :call
    end,
    'oj_mimic_json' => lambda do |_config|
      require 'oj'
      Oj.mimic_JSON
    end,
    'oj_optimize_rails' => lambda do |_config|
      require 'oj'
      Oj.optimize_rails
    end,
    'yajl' => lambda do |config|
      require 'yajl'
      config.generator = Yajl::Encoder
      config.method = :encode
    end
  }.freeze

  MixedRow = Struct.new(:id, :name, :score, :active, :note, :created_at, keyword_init: true)

  def self.mixed_objects
    Array.new(OBJECT_COUNT) do |i|
      MixedRow.new(id: i, name: "name-#{i}", score: i * 1.5, active: i.even?, note: nil,
                   created_at: Time.at(EPOCH + i, in: '+03:00'))
    end
  end

  def self.mixed_blueprint(datetime_format: nil)
    Class.new(Blueprinter::Base) do
      identifier :id
      fields :name, :score, :active, :note
      field :created_at, datetime_format: datetime_format
    end
  end

  # name => [blueprint, objects]
  def self.payload(name)
    case name
    when 'strings' then build_blueprint(6, OBJECT_COUNT)
    when 'mixed' then [mixed_blueprint, mixed_objects]
    when 'mixed_datetime_format' then [mixed_blueprint(datetime_format: '%FT%T%:z'), mixed_objects]
    else raise ArgumentError, "unknown payload #{name}"
    end
  end

  def self.run(serializer, payload_name)
    Blueprinter.configure { |config| SERIALIZERS.fetch(serializer).call(config) }
    blueprint, objects = payload(payload_name)
    prepared = blueprint.render_as_hash(objects)

    render = sample_duration { blueprint.render(objects) }
    encode = sample_duration { Blueprinter.configuration.jsonify(prepared) }
    output = blueprint.render(objects)

    {
      renders_per_sec: 1.0 / render[:median],
      render_allocations: allocations { blueprint.render(objects) },
      encodes_per_sec: 1.0 / encode[:median],
      encode_allocations: allocations { Blueprinter.configuration.jsonify(prepared) },
      json_generate_replaced: JSON.method(:generate).source_location.nil?,
      parsed: JSON.parse(output).first(3),
      sample_time: payload_name == 'strings' ? nil : JSON.parse(output).first['created_at']
    }
  end
end

puts JSON.generate(SerializerProbe.run(ARGV[0], ARGV[1]))
$stdout.flush
# exit! skips the at_exit hook that minitest/autorun (pulled in by benchmark_helper) installs.
exit!(0)

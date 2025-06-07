# frozen_string_literal: true

require 'benchmark'
require 'blueprinter'

NUM_FIELDS = 100
NUM_OBJECTS = 50
NUM_COLLECTIONS = 25

class CategoryBlueprintV1 < Blueprinter::Base
  field :name
end

class PartBlueprintV1 < Blueprinter::Base
  field :num
end

class WidgetBlueprintV1 < Blueprinter::Base
  NUM_FIELDS.times { |i| field :"name_#{i}" }
  NUM_OBJECTS.times { |i| association :"category_#{i}", blueprint: CategoryBlueprintV1 }
  NUM_COLLECTIONS.times { |i| association  :"parts_#{i}", blueprint: PartBlueprintV1 }
end

class ApplicationBlueprintV2 < Blueprinter::V2::Base
end

class CategoryBlueprintV2 < ApplicationBlueprintV2
  field :name
end

class PartBlueprintV2 < ApplicationBlueprintV2
  field :num
end

class WidgetBlueprintV2 < ApplicationBlueprintV2
  NUM_FIELDS.times { |i| field :"name_#{i}" }
  NUM_OBJECTS.times { |i| object :"category_#{i}", CategoryBlueprintV2 }
  NUM_COLLECTIONS.times { |i| collection :"parts_#{i}", PartBlueprintV2 }
end

puts "#{NUM_FIELDS} fields, #{NUM_OBJECTS} objects, #{NUM_COLLECTIONS} collections"

results = Benchmark.bmbm do |x|
  widgets = 100_000.times.map do |n|
    {}.merge(
      NUM_FIELDS.times.each_with_object({}) { |i, obj| obj[:"name_#{i}"] = "Widget #{n}" },
      NUM_OBJECTS.times.each_with_object({}) { |i, obj| obj[:"category_#{i}"] = { name: "Category #{n % 50}" } },
      NUM_COLLECTIONS.times.each_with_object({}) { |i, obj| obj[:"parts_#{i}"] = (1..rand(1..10)).map { |n| { num: n } } },
    )
  end

  [
    [10_000, 10],
    [1000, 100],
    [500, 100],
    [250, 100],
    [100, 250],
    [25, 500],
    [5, 1000],
    [1, 1000],
  ].each do |(n, m)|
    fmt_n = n.to_s.chars.reverse.each_slice(3).map(&:join).join(',').reverse
    list = widgets[0,n]
    x.report "#{fmt_n} widgets #{m}x: V1" do
      m.times { WidgetBlueprintV1.render_as_hash(list) }
    end

    x.report "#{fmt_n} widgets #{m}x: V2" do
      m.times { WidgetBlueprintV2.render(list).to_hash }
    end
  end
end

puts ""
results.
  group_by { |res| res.label[/.+:/].ljust 16 }.
  each do |label, (a, b)|
    v1 = (a.label =~ /V1/ ? a : b).real
    v2 = (a.label =~ /V2/ ? a : b).real

    if v2 < v1
      n = (100 - (v2 / v1) * 100).round(2)
      pcnt = ('%0.2f' % n).rjust(5, '0')
      puts "#{label} V2 #{pcnt}% faster (#{'%.4f' % (v1 - v2)} sec)"
    else
      n = (100 - (v1 / v2) * 100).round(2)
      pcnt = ('%0.2f' % n).rjust(5, '0')
      puts "#{label} V2 #{pcnt}% slower (#{'%.4f' % (v2 - v1)} sec)"
    end
  end

# frozen_string_literal: true

require 'benchmark'
require 'blueprinter'

NUM_FIELDS = 20
NUM_OBJECTS = 5
NUM_COLLECTIONS = 2

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
  NUM_OBJECTS.times { |i| association :"category_#{i}", CategoryBlueprintV2 }
  NUM_COLLECTIONS.times { |i| association :"parts_#{i}", [PartBlueprintV2] }
end

puts "#{NUM_FIELDS} fields, #{NUM_OBJECTS} objects, #{NUM_COLLECTIONS} collections"

M = 100
results = Benchmark.bmbm do |x|
  widgets = 100_000.times.map do |n|
    {}.merge(
      NUM_FIELDS.times.each_with_object({}) { |i, obj| obj[:"name_#{i}"] = "Widget #{n}" },
      NUM_OBJECTS.times.each_with_object({}) { |i, obj| obj[:"category_#{i}"] = { name: "Category #{n % 50}" } },
      NUM_COLLECTIONS.times.each_with_object({}) { |i, obj| obj[:"parts_#{i}"] = (1..rand(1..10)).map { |n| { num: n } } },
    )
  end

  [1000, 500, 250, 100, 25, 5, 1].each do |n|
    fmt_n = n.to_s.chars.reverse.each_slice(3).map(&:join).join(',').reverse
    list = widgets[0,n]
    x.report "#{fmt_n} widgets #{M}x: V1" do
      M.times { WidgetBlueprintV1.render_as_hash(list) }
      # M.times { list.each { |w| WidgetBlueprintV1.render_as_hash(w) } }
    end

    x.report "#{fmt_n} widgets #{M}x: V2" do
      M.times { WidgetBlueprintV2.render(list).to_hash }
      # M.times { list.each { |w| WidgetBlueprintV2.render(w).to_hash } }
    end
  end
end

puts ""
results.
  group_by { |res| res.label[/.+:/].ljust 16 }.
  each do |label, (a, b)|
    v1 = (a.label =~ /V1/ ? a : b).real
    v2 = (a.label =~ /V2/ ? a : b).real

    n = ((v2 - v1) / v1) * 100
    pct = ('%0.2f' % n.abs).rjust(5, '0')
    sign = n < 0 ? "-" : "+"

    puts "#{label} V2 change: #{sign}#{pct}%"
  end

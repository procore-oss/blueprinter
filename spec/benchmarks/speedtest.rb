# frozen_string_literal: true

require 'benchmark'
require 'blueprinter'

NAME_FIELDS = 10

class CategoryBlueprintV1 < Blueprinter::Base
  field :name
end

class PartBlueprintV1 < Blueprinter::Base
  field :num
end

class WidgetBlueprintV1 < Blueprinter::Base
  NAME_FIELDS.times { |i| field :"name#{i}" }
  association :category, blueprint: CategoryBlueprintV1
  association :parts, blueprint: PartBlueprintV1
end

class CategoryBlueprintV2 < Blueprinter::V2::Base
  field :name
end

class PartBlueprintV2 < Blueprinter::V2::Base
  field :num
end

class WidgetBlueprintV2 < Blueprinter::V2::Base
  NAME_FIELDS.times { |i| field :"name#{i}" }
  object :category, CategoryBlueprintV2
  collection :parts, PartBlueprintV2
end

results = Benchmark.bmbm do |x|
  widgets = 100_000.times.map do |n|
    NAME_FIELDS.times.
      each_with_object({}) { |i, obj| obj[:"name#{i}"] = "Widget #{n}" }.
      merge({
        category: { name: "Category #{n % 50}" },
        parts: (1..rand(1..10)).map { |n| { num: n } }
      })
  end

  [
    [100_000, 1],
    [10_000, 10],
    [1000, 100],
    [500, 100],
    [250, 100],
    [100, 100],
    [25, 100],
    [5, 100],
    [1, 100],
  ].each do |(n, m)|
    fmt_n = n.to_s.chars.reverse.each_slice(3).map(&:join).join(',').reverse
    list = widgets[0,n]
    x.report "#{fmt_n} widgets: V1" do
      m.times { WidgetBlueprintV1.render(list) }
    end

    x.report "#{fmt_n} widgets: V2" do
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

# frozen_string_literal: true

require 'benchmark'
require 'blueprinter'

class CategoryBlueprintV1 < Blueprinter::Base
  field :name
end

class PartBlueprintV1 < Blueprinter::Base
  field :num
end

class WidgetBlueprintV1 < Blueprinter::Base
  field :name1
  field :name2
  field :name3
  field :name4
  field :name5
  field :name6
  field :name7
  field :name8
  field :name9
  field :name10
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
  field :name1
  field :name2
  field :name3
  field :name4
  field :name5
  field :name6
  field :name7
  field :name8
  field :name9
  field :name10
  object :category, CategoryBlueprintV2
  collection :parts, PartBlueprintV2
end

results = Benchmark.bmbm do |x|
  widgets = 100_000.times.map do |n|
    {
      name1: "Widget #{n}",
      name2: "Widget #{n}",
      name3: "Widget #{n}",
      name4: "Widget #{n}",
      name5: "Widget #{n}",
      name6: "Widget #{n}",
      name7: "Widget #{n}",
      name8: "Widget #{n}",
      name9: "Widget #{n}",
      name10: "Widget #{n}",
      category: { name: "Category #{n % 50}" },
      parts: (1..rand(1..10)).map { |n| { num: n } }
    }
  end

  x.report 'Massive: V1' do
    WidgetBlueprintV1.render(widgets)
  end

  x.report 'Massive: V2' do
    WidgetBlueprintV2.render(widgets).to_hash
  end

  x.report 'Large: V1' do
    list = widgets[0,10_000]
    10.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Large: V2' do
    list = widgets[0,10_000]
    10.times { WidgetBlueprintV2.render(list).to_hash }
  end

  x.report 'Medium: V1' do
    list = widgets[0,1000]
    100.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Medium: V2' do
    list = widgets[0,1000]
    100.times { WidgetBlueprintV2.render(list).to_hash }
  end

  x.report 'Small: V1' do
    list = widgets[0,100]
    100.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Small: V2' do
    list = widgets[0,100]
    100.times { WidgetBlueprintV2.render(list).to_hash }
  end

  x.report 'Tiny: V1' do
    list = widgets[0,25]
    100.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Tiny: V2' do
    list = widgets[0,25]
    100.times { WidgetBlueprintV2.render(list).to_hash }
  end

  x.report 'Micro: V1' do
    list = widgets[0,5]
    100.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Micro: V2' do
    list = widgets[0,5]
    100.times { WidgetBlueprintV2.render(list).to_hash }
  end

  x.report 'Nano: V1' do
    list = widgets[0,1]
    100.times { WidgetBlueprintV1.render(list) }
  end

  x.report 'Nano: V2' do
    list = widgets[0,1]
    100.times { WidgetBlueprintV2.render(list).to_hash }
  end
end

puts ""
results.
  group_by { |res| res.label[/.+:/].ljust 8 }.
  each do |label, (a, b)|
    v1 = (a.label =~ /V1/ ? a : b).real
    v2 = (a.label =~ /V2/ ? a : b).real

    if v2 < v1
      n = (100 - (v2 / v1) * 100).round(2)
      puts "#{label} V2 #{'%2.2f' % n}% faster (#{'%.4f' % (v1 - v2)} sec)"
    else
      n = (100 - (v1 / v2) * 100).round(2)
      puts "#{label} V2 #{'%2.2f' % n}% slower (#{'%.4f' % (v2 - v1)} sec)"
    end
  end

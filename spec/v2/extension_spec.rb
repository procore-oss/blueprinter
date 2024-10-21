# frozen_string_literal: true

require 'date'
require 'blueprinter/v2/extension'

describe Blueprinter::V2::Extension do
  context 'format' do
    subject { Class.new(described_class) }
    it 'should add a block formatter' do
      iso8601 = ->(x, _opts) { x.iso8601 }
      subject.format(Date, &iso8601)
      subject.format(Time, &iso8601)

      expect(subject.formatters[Date]).to eq iso8601
      expect(subject.formatters[Time]).to eq iso8601
    end

    it 'should add a method formatter' do
      subject.format(Date, :fmt_date)
      subject.format(Time, :fmt_time)

      expect(subject.formatters[Date]).to eq :fmt_date
      expect(subject.formatters[Time]).to eq :fmt_time
    end
  end
end

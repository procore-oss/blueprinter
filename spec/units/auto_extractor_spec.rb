# frozen_string_literal: true

require 'date'
require 'ostruct'
require 'blueprinter/extractors/auto_extractor'

describe Blueprinter::AutoExtractor do
  let(:extractor) { described_class.new }
  let(:formatter) { extractor.instance_variable_get(:@datetime_formatter) }
  let(:birthday) { Date.new(1994, 3, 4) }
  let(:object) { OpenStruct.new(name: 'Meg', birthday: birthday) }

  after { reset_blueprinter_config! }

  def extract(field_name, options = {})
    extractor.extract(field_name, object, { view: :default }, options)
  end

  context 'when no datetime format is configured' do
    it 'returns the value without calling the formatter' do
      expect(formatter).not_to receive(:format)

      expect(extract(:birthday)).to equal(birthday)
      expect(extract(:name)).to eq('Meg')
    end

    it 'still applies a field default' do
      expect(formatter).not_to receive(:format)

      expect(extract(:nickname, default: 'none')).to eq('none')
    end
  end

  context 'when the field sets datetime_format' do
    it 'formats the value' do
      expect(extract(:birthday, datetime_format: '%Y')).to eq('1994')
    end

    it 'raises for a value that cannot be formatted' do
      expect { extract(:name, datetime_format: '%Y') }
        .to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError)
    end
  end

  context 'when the global datetime_format is set' do
    before { Blueprinter.configure { |config| config.datetime_format = '%Y' } }

    it 'formats a date' do
      expect(extract(:birthday)).to eq('1994')
    end

    it 'formats any object that implements strftime' do
      widget = Class.new do
        def strftime(format)
          "ok:#{format}"
        end
      end.new

      expect(extractor.extract(:updated_at, OpenStruct.new(updated_at: widget), {}, {})).to eq('ok:%Y')
    end

    it 'leaves a non-date unchanged' do
      expect(extract(:name)).to eq('Meg')
    end
  end

  it 'raises for a false global datetime_format' do
    Blueprinter.configure { |config| config.datetime_format = false }

    expect { extract(:birthday) }
      .to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError)
  end

  it 'applies a global format set after an earlier extract' do
    expect(extract(:birthday)).to equal(birthday)

    Blueprinter.configure { |config| config.datetime_format = '%m/%d/%Y' }

    expect(extract(:birthday)).to eq('03/04/1994')
  end
end

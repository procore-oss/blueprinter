describe '::View' do
  let(:formatter) { Blueprinter::DateTimeFormatter.new }
  let(:valid_date) { Date.new(1994, 3, 4) }
  let(:invalid_date) { "invalid_date" }
  let(:invalid_field_options) { { datetime_format: 5 } }

  describe '#format(datetime, options)' do
    context 'Given no datetime format' do
      it 'should return original date' do
        expect(formatter.format(valid_date, {})).to eq(valid_date)
      end
    end

    context 'Given string datetime format' do
      let(:field_options) { { datetime_format: "%m/%d/%Y" } }

      context 'and given valid datetime' do
        it 'should return formatted date via strftime' do
          expect(formatter.format(valid_date, field_options)).to eq("03/04/1994")
        end
      end

      context 'and given invalid datetime' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(invalid_date, field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end

      context 'and given invalid format' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(valid_date, invalid_field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end
    end

    context 'Given Proc datetime format' do
      let(:field_options) { { datetime_format: -> datetime { datetime.year.to_s } } }

      context 'and given valid datetime' do
        it 'should return formatted date via proc' do
          expect(formatter.format(valid_date, field_options)).to eq("1994")
        end
      end

      context 'and given invalid datetime' do
        it 'raises original error from Proc' do
          expect{formatter.format(invalid_date, field_options)}.to raise_error(NoMethodError)
        end
      end

      context 'and given invalid format' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(valid_date, invalid_field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end
    end

    context 'Given invalid datetime format' do
      let(:field_options) { { datetime_format: 5 } }

      context 'and given valid datetime' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(valid_date, field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end

      context 'and given invalid datetime' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(invalid_date, field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end

      context 'and given invalid format' do
        it 'raises a BlueprinterError' do
          expect{formatter.format(invalid_date, invalid_field_options)}.to raise_error(Blueprinter::BlueprinterError)
        end
      end
    end
  end
end

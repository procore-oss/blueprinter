# frozen_string_literal: true

describe '::View' do
  let(:view) { Blueprinter::View.new('Basic View') }
  let(:field) { MockField.new(:first_name) }

  describe '#include_view(:view_name)' do
    it 'should return [:view_name]' do
      expect(view.include_view(:extended)).to eq([:extended])
    end
    it 'should set #included_view_names to [:view_name]' do
      view.include_view(:extended)
      expect(view.included_view_names).to eq([:extended])
    end
  end

  describe '#include_views(:view_name)' do
    it 'should return [:view_name]' do
      expect(view.include_views([:normal, :special])).to eq([:normal, :special])
    end
    it 'should set #included_view_names to [:view_name]' do
      view.include_views([:normal, :special])
      expect(view.included_view_names).to eq([:normal, :special])
    end
  end

  describe '#exclude_field(:view_name)' do
    it 'should return [:view_name]' do
      expect(view.exclude_field(:last_name)).to eq([:last_name])
    end
    it 'should set #excluded_field_names to [:view_name]' do
      view.exclude_field(:last_name)
      expect(view.excluded_field_names).to eq([:last_name])
    end
  end

  describe '#exclude_fields(:view_name)' do
    it 'should return [:view_name]' do
      expect(view.exclude_fields([:last_name,:middle_name])).to eq([:last_name,:middle_name])
    end
    it 'should set #excluded_field_names to [:view_name]' do
      view.exclude_fields([:last_name,:middle_name])
      expect(view.excluded_field_names).to eq([:last_name,:middle_name])
    end
  end

  describe '#<<(field)' do
    context 'Given a field that does not exist' do
      it('should return field') { expect(view << field).to eq(field) }
      it('should set #fields to {field.name => field}') do
        view << field
        expect(view.fields).to eq({first_name: field})
      end
    end

    context 'Given a field that already exists' do
      let(:aliased_field) { MockField.new(:fname, :first_name) }

      before { view << field }

      it 'overrides previous definition' do
        view << aliased_field

        expect(view.fields).to eq(first_name: aliased_field)
      end
    end
  end

  describe '#fields' do
    context 'Given no fields' do
      it { expect(view.fields).to eq({}) }
    end

    context 'Given existing fields' do
      before { view << field }
      it('should eq {field.name => field}') do
        expect(view.fields).to eq({first_name: field})
      end
    end
  end

  context 'with default transform' do
    let(:default_transform) do
      class DefaultTransform < Blueprinter::Transformer; end
      DefaultTransform
    end
    let(:override_transform) do
      class OverrideTransform < Blueprinter::Transformer; end
      OverrideTransform
    end
    let(:view_with_default_transform) do
      Blueprinter::View.new('View with default transform')
    end
    let(:view_with_override_transform) do
      Blueprinter::View.new('View with override transform', transformers: [override_transform])
    end

    before do
      Blueprinter.configure { |config| config.default_transformers = [default_transform] }
    end

    describe '#transformers' do
      it 'should return the default transformers' do
        expect(view_with_default_transform.transformers).to eq([default_transform])
      end

      it 'should allow for overriding the default transformers' do
        expect(view_with_override_transform.transformers).to eq([override_transform])
      end
    end
  end
end

class MockField
  attr_reader :name, :method
  def initialize(method, name = nil)
    @method = method
    @name = name || method
  end
end

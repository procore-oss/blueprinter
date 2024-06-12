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

  describe "#finalize" do
    let(:fields) { {a: double, b: double, c: double} }
    let(:view) { Blueprinter::View.new('With IF', fields: fields, local_options: { if: if_condition }) }

    context "without an if condition" do
      let(:if_condition) { nil }

      it "does nothing" do
        view.finalize
      end
    end

    context "when there is an if condition" do
      let(:if_condition) { :some_condition }

      it "adds the condition to each field" do
        expect(fields[:a]).to receive(:add_if).with(if_condition)
        expect(fields[:b]).to receive(:add_if).with(if_condition)
        expect(fields[:c]).to receive(:add_if).with(if_condition)

        view.finalize
      end
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
  end
end

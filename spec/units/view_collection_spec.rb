# frozen_string_literal: true

describe 'ViewCollection' do
  let(:view_collection) { Blueprinter::ViewCollection.new }

  let!(:default_view) { view_collection[:default] }
  let!(:view) { view_collection[:view] }

  let(:default_field) { MockField.new(:default_field) }
  let(:view_field) { MockField.new(:view_field) }
  let(:new_field) { MockField.new(:new_field) }

  before do
    default_view << default_field
    view << view_field
  end

  describe '#initialize' do
    it 'should create an identifier, view, and default view' do
      expect(view_collection.views.keys).to eq([:identifier, :default, :view])
    end
  end

  describe '#[]' do
    it 'should return the view if it exists' do
      expect(view_collection.views[:default]).to eq(default_view)
    end

    it 'should create the view if it does not exist' do
      new_view = view_collection[:new_view]
      expect(view_collection.views[:new_view]).to eq(new_view)
    end
  end

  describe '#view?' do
    it 'should return true if the view exists' do
      expect(view_collection.view?(:default)).to eq(true)
    end

    it 'should return false if the view does not exist' do
      expect(view_collection.view?(:missing_view)).to eq(false)
    end
  end

  describe '#inherit' do
    let(:parent_view_collection) { Blueprinter::ViewCollection.new }

    before do
      parent_view_collection[:view] << new_field
    end

    it 'should inherit the fields from the parent view collection' do
      view_collection.inherit(parent_view_collection)
      expect(view.fields).to include(parent_view_collection[:view].fields)
    end
  end

  describe '#fields_for' do
    it 'should return the fields for the view' do
      expect(view_collection.fields_for(:view)).to eq([default_field, view_field])
    end
  end

  describe '#transformers' do
    let(:transformer) { Blueprinter::Transformer.new }

    before do
      view.add_transformer(transformer)
    end

    it 'should return the transformers for the view' do
      expect(view_collection.transformers(:view)).to eq([transformer])
    end

    it 'should not return any transformers for another view' do
      view_collection[:foo]
      expect(view_collection.transformers(:foo)).to eq([])
    end

    context 'default view transformer' do
      let(:default_transformer) { Blueprinter::Transformer.new }

      before do
        default_view.add_transformer(default_transformer)
      end

      it 'should return the transformers for the default view' do
        expect(view_collection.transformers(:default)).to eq([default_transformer])
      end

      it 'should return both the view transformer and default transformers for the view' do
        expect(view_collection.transformers(:view)).to eq([transformer, default_transformer])
      end
    end

    context 'include view transformer' do
      let!(:includes_view) { view_collection[:includes_view] }
      let!(:nested_view) { view_collection[:nested_view] }

      before do
        includes_view.include_view(:view)
      end

      it 'should return the transformers for the included view' do
        expect(view_collection.transformers(:includes_view)).to include(transformer)
      end

      it 'should return the transformers for the nested included view' do
        nested_view.include_view(:includes_view)
        expect(view_collection.transformers(:nested_view)).to include(transformer)
      end

      it 'should only return unique transformers' do
        includes_view.add_transformer(transformer)
        transformers = view_collection.transformers(:nested_view)
        expect(transformers.uniq.length == transformers.length).to eq(true)
      end
    end

    context 'configured default transformers' do
      let(:default_transformer) { Blueprinter::Transformer.new }

      before do
        Blueprinter.configure { |config| config.default_transformers = [default_transformer] }
      end

      context 'with no transformers' do
        let!(:new_view) { view_collection[:new_view] }
        
        it 'should return the configured default transformers' do
          expect(view_collection.transformers(:new_view)).to include(default_transformer)
        end
      end

      context 'with transformers' do
        it 'should not return the configured default transformers' do
          expect(view_collection.transformers(:view)).to_not include(default_transformer)
        end
      end
    end
  end
end

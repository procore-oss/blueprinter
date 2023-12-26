# frozen_string_literal: true

describe 'ViewCollection' do
  let(:view_collection) { Blueprinter::ViewCollection.new }
  let(:default_field) { MockField.new(:foo) }
  let(:new_field) { MockField.new(:bar) }

  before do
    view_collection[:default] << default_field
    view_collection[:view]
  end

  describe '#initialize' do
    it 'should create an identifier, view, and default view' do
      expect(view_collection.views.keys).to eq([:identifier, :default, :view])
    end
  end

  describe '#[]' do
    it 'should return the view if it exists' do
      expect(view_collection[:default]).to eq(view_collection.views[:default])
    end

    it 'should create the view if it does not exist' do
      expect(view_collection[:view]).to eq(view_collection.views[:view])
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

    it 'should inherit views from the parent' do
      view_collection.inherit(parent_view_collection)
      expect(view_collection[:view].fields).to eq(parent_view_collection[:view].fields)
    end
  end

  describe '#fields_for' do
    it 'should return the fields for the view' do
      view_collection[:view] << new_field
      expect(view_collection.fields_for(:view)).to eq([new_field, default_field])
    end
  end

  describe '#transformers' do
    let(:transformer) { Blueprinter::Transformer.new }

    context 'default view transformer' do
      before do
        view_collection[:default].add_transformer(transformer)
      end

      it 'should return the transformers for the default view' do
        expect(view_collection.transformers(:default)).to eq([transformer])
      end

      it 'should return the default transformers for the view' do
        expect(view_collection.transformers(:view)).to eq([transformer])
      end
    end

    context 'view transformer' do
      before do
        view_collection[:view].add_transformer(transformer)
      end

      it 'should return the transformers for the view' do
        expect(view_collection.transformers(:view)).to eq([transformer])
      end

      it 'should not return any transformers for another view' do
        view_collection[:foo]
        expect(view_collection.transformers(:foo)).to eq([])
      end

      context 'include view transformer' do
        before do
          view_collection[:includes_view].include_view(:view)
        end

        it 'should return the transformers for the included view' do
          expect(view_collection.transformers(:includes_view)).to eq([transformer])
        end
  
        it 'should return the transformers for the nested included view' do
          view_collection[:nested_view].include_view(:includes_view)
          expect(view_collection.transformers(:nested_view)).to eq([transformer])
        end
      end
    end
  end
end

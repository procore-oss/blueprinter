# frozen_string_literal: true

require 'blueprinter/view_collection'

describe 'ViewCollection' do
  subject(:view_collection) { Blueprinter::ViewCollection.new }

  let!(:default_view) { view_collection[:default] }
  let!(:view) { view_collection[:view] }

  let(:default_field) { MockField.new(:default_field) }
  let(:view_field) { MockField.new(:view_field) }
  let(:new_field) { MockField.new(:new_field) }

  let(:default_transformer) { Blueprinter::Transformer.new }

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
    it 'returns the fields for the view' do
      expect(view_collection.fields_for(:view)).to eq([default_field, view_field])
    end

    it 'returns a frozen array' do
      expect(view_collection.fields_for(:view)).to be_frozen
    end
  end

  describe '#transformers' do
    let(:transformer) { Blueprinter::Transformer.new }

    before do
      view.add_transformer(transformer)
    end

    it 'returns the transformers for the view' do
      expect(view_collection.transformers(:view)).to eq([transformer])
    end

    it 'returns a frozen array' do
      expect(view_collection.transformers(:view)).to be_frozen
    end

    it 'does not return any transformers for another view' do
      view_collection[:foo]
      expect(view_collection.transformers(:foo)).to eq([])
    end

    context 'default view transformer' do
      before do
        default_view.add_transformer(default_transformer)
      end

      it 'should return the transformers for the default view' do
        expect(view_collection.transformers(:default)).to eq([default_transformer])
      end

      it 'should return both the view transformer and default transformers for the view' do
        expect(view_collection.transformers(:view)).to eq([default_transformer, transformer])
      end

      it 'should not alter view transformers of the view on subsequent fetches' do
        view_collection.transformers(:default)
        expect { view_collection.transformers(:default) }
          .not_to change(default_view.view_transformers, :count)
      end
    end

    context 'include view transformer' do
      let!(:includes_view) { view_collection[:includes_view] }
      let!(:nested_view) { view_collection[:nested_view] }

      before do
        includes_view.include_view(:view)
        nested_view.include_view(:includes_view)
      end

      it 'should return the transformers for the included view' do
        expect(view_collection.transformers(:includes_view)).to include(transformer)
      end

      it 'should return the transformers for the nested included view' do
        expect(view_collection.transformers(:nested_view)).to include(transformer)
      end

      it 'should only return unique transformers' do
        includes_view.add_transformer(transformer)
        transformers = view_collection.transformers(:nested_view)
        expect(transformers.uniq.length == transformers.length).to eq(true)
      end

      it 'should return transformers in the correct order' do
        includes_view_transformer = Blueprinter::Transformer.new
        nested_view_transformer = Blueprinter::Transformer.new

        default_view.add_transformer(default_transformer)
        includes_view.add_transformer(includes_view_transformer)
        nested_view.add_transformer(nested_view_transformer)

        expect(view_collection.transformers(:nested_view)).to eq([
          default_transformer, nested_view_transformer, includes_view_transformer, transformer
        ])
      end
    end

    context 'global default transformers' do
      before do
        Blueprinter.configure { |config| config.default_transformers = [default_transformer] }
      end

      context 'with no view transformers' do
        let!(:new_view) { view_collection[:new_view] }

        it 'should return the global default transformers' do
          expect(view_collection.transformers(:new_view)).to include(default_transformer)
        end
      end

      context 'with view transformers' do
        it 'should not return the global default transformers' do
          expect(view_collection.transformers(:view)).to_not include(default_transformer)
        end
      end
    end
  end

  describe 'cache lifecycle' do
    it 'caches fields_for results across calls' do
      first_call = view_collection.fields_for(:view)
      second_call = view_collection.fields_for(:view)

      expect(first_call).to equal(second_call)
    end

    it 'invalidates cache when inherit is called' do
      child = Blueprinter::ViewCollection.new
      child[:default] << default_field

      # Build the cache
      fields_before = child.fields_for(:default)

      # Inherit new fields — cache should be invalidated
      parent = Blueprinter::ViewCollection.new
      parent[:default] << new_field
      child.inherit(parent)

      fields_after = child.fields_for(:default)
      expect(fields_after).not_to equal(fields_before)
      expect(fields_after).to include(new_field)
    end

    it 'child inherits parent fields without mutating the parent' do
      parent = Blueprinter::ViewCollection.new
      parent[:default] << default_field
      parent_fields = parent.fields_for(:default)

      child = Blueprinter::ViewCollection.new
      child.inherit(parent)
      child[:default] << view_field

      # Parent cache is untouched
      expect(parent.fields_for(:default)).to equal(parent_fields)
      expect(parent.fields_for(:default)).not_to include(view_field)

      # Child has both parent and its own fields
      expect(child.fields_for(:default)).to include(default_field)
      expect(child.fields_for(:default)).to include(view_field)
    end

    it 'invalidates cache when a new view is created via []' do
      fields_before = view_collection.fields_for(:view)

      view_collection[:brand_new_view]

      fields_after = view_collection.fields_for(:view)
      expect(fields_after).not_to equal(fields_before)
      expect(fields_after).to eq(fields_before)
    end

    it 'invalidates cache when invalidate_cache! is called after view mutation' do
      # Build the cache by accessing fields
      fields_before = view_collection.fields_for(:view)
      expect(fields_before).to include(default_field, view_field)

      # Mutate the view after cache is built (simulates excludes inside a view block)
      view.exclude_field(:default_field)
      view_collection.invalidate_cache!

      # Cache should rebuild with the exclusion applied
      fields_after = view_collection.fields_for(:view)
      expect(fields_after).not_to include(default_field)
      expect(fields_after).to include(view_field)
    end
  end
end

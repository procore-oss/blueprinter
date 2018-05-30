shared_examples 'Base::render' do
  context 'Given blueprint has ::field' do
    let(:result) { '{"first_name":"Meg","id":' + obj_id + '}' }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        field :id
        field :first_name
      end
    end
    it('returns json with specified fields') { should eq(result) }
  end

  context 'Given blueprint has ::fields' do
    let(:result) do
      '{"id":' + obj_id + ',"description":"A person","first_name":"Meg"}'
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        fields :first_name, :description
      end
    end
    it('returns json with specified fields') { should eq(result) }
  end

  context 'Given blueprint has ::field with a :name argument' do
    let(:result) { '{"first_name":"Meg","identifier":' + obj_id + '}' }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        field :id, name: :identifier
        field :first_name
      end
    end
    it('returns json with a renamed field') { should eq(result) }
  end

  context 'Given blueprint has ::field with a :extractor argument' do
    let(:result) { '{"first_name":"MEG","id":' + obj_id + '}' }
    let(:blueprint) do
      extractor = Class.new(Blueprinter::Extractor) do
        def extract(field_name, object, _local_options, _options={})
          object[field_name].upcase
        end
      end
      Class.new(Blueprinter::Base) do
        field :id
        field :first_name, extractor: extractor
      end
    end
    it('returns json derived from a custom extractor') { should eq(result) }
  end

  context 'Given blueprint has ::field with a :datetime_format argument' do
    let(:result) do
      '{"id":' + obj_id + ',"birthday":"03/04/1994"}'
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday, datetime_format: "%m/%d/%Y"
      end
    end
    it('returns json with a formatted field') { should eq(result) }
  end

  context 'Given blueprint has a :datetime_format argument on an invalid ::field' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name, datetime_format: "%m/%d/%Y"
      end
    end
    it('raises a BlueprinterError') { expect{subject}.to raise_error(Blueprinter::BlueprinterError) }
  end

  context 'Given blueprint has ::view' do
    let(:normal) do
      ['{"id":' + obj_id + '', '"employer":"Procore"', '"first_name":"Meg"',
      '"position":"Manager"}'].join(',')
    end
    let(:ext) do
      ['{"id":' + obj_id + '', '"description":"A person"', '"employer":"Procore"',
      '"first_name":"Meg"', '"position":"Manager"}'].join(',')
    end
    let(:special) do
      ['{"id":' + obj_id + '', '"description":"A person"', '"employer":"Procore"',
      '"first_name":"Meg"}'].join(',')
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        view :normal do
          fields :first_name, :position
          field :company, name: :employer
        end
        view :extended do
          include_view :normal
          field :description
        end
        view :special do
          include_view :extended
          exclude :position
        end
      end
    end
    it('returns json derived from a view') do
      expect(blueprint.render(obj, view: :normal)).to eq(normal)
      expect(blueprint.render(obj, view: :extended)).to eq(ext)
      expect(blueprint.render(obj, view: :special)).to eq(special)
    end
  end

  context 'Given blueprint has ::field with a block' do
    let(:result) { '{"id":' + obj_id + ',"position_and_company":"Manager at Procore"}' }
    let(:blueprint) { blueprint_with_block }
    it('returns json with values derived from a block') { should eq(result) }
  end

  context 'Given ::render with options' do
    subject { blueprint.render(obj, vehicle: vehicle) }
    let(:result) { '{"id":' + obj_id + ',"vehicle_make":"Super Car"}' }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :vehicle_make do |_obj, options|
          "#{options[:vehicle][:make]}"
        end
      end
    end
    it('returns json with values derived from options') { should eq(result) }
  end
end

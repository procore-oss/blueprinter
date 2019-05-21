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
      '{"id":' + obj_id + ',"birthday":"03/04/1994","deleted_at":null}'
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday,   datetime_format: "%m/%d/%Y"
        field :deleted_at, datetime_format: '%FT%T%:z'
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

  context "Given blueprint has ::field with nil value" do
    before do
      obj[:first_name] = nil
    end

    context "Given default value is not provided" do
      let(:result) { '{"first_name":null,"id":' + obj_id + '}' }
      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          field :id
          field :first_name
        end
      end
      it('returns json with specified fields') { should eq(result) }
    end

    context "Given default value is provided" do
      let(:result) { '{"first_name":"Unknown","id":' + obj_id + '}' }
      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          field :id
          field :first_name, default: "Unknown"
        end
      end
      it('returns json with specified fields') {
        should eq(result)
      }
    end
  end

  context 'Given blueprint has ::field with a conditional argument' do
    variants = %i[proc method].product([true, false])

    let(:if_value) { true }
    let(:unless_value) { false }
    let(:field_options) { {} }
    let(:local_options) { { x: 1, y: 2 } }
    let(:if_proc) { ->(_obj, _local_opts) { if_value } }
    let(:unless_proc) { ->(_obj, _local_opts) { unless_value } }
    let(:blueprint) do
      f_options = field_options

      bp = Class.new(Blueprinter::Base) do
        field :id
        field :first_name, f_options
      end
      bp.instance_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.if_method(_object, _options)
              #{if_value}
            end

            def self.unless_method(_object, _options)
              #{unless_value}
            end
          RUBY
      bp
    end
    let(:result_with_first_name) do
      %({"first_name":"Meg","id":#{obj_id}})
    end
    let(:result_without_first_name) { %({"id":#{obj_id}}) }
    subject { blueprint.render(obj, local_options) }

    shared_examples 'serializes the conditional field' do
      it 'serializes the conditional field' do
        should eq(result_with_first_name)
      end
    end

    shared_examples 'does not serialize the conditional field' do
      it 'does not serialize the conditional field' do
        should eq(result_without_first_name)
      end
    end

    variants.each do |type, value|
      context "Given the conditional is :if #{type} returning #{value}" do
        let(:if_value) { value }

        before do
          field_options[:if] = type == :method ? :if_method : if_proc
        end

        context 'and no :unless conditional' do
          if value
            include_examples 'serializes the conditional field'
          else
            include_examples 'does not serialize the conditional field'
          end
        end

        variants.each do |other_type, other_value|
          context "and :unless conditional is #{other_type} returning #{other_value}" do
            let(:unless_value) { other_value }
            before do
              field_options[:unless] = if type == :method then :unless_method
                                       else unless_proc
                                       end
            end

            if value && !other_value
              include_examples 'serializes the conditional field'
            else
              include_examples 'does not serialize the conditional field'
            end
          end
        end
      end

      context "Given the conditional is :unless #{type} returning #{value} and no :if conditional" do
        let(:unless_value) { value }
        before do
          field_options[:unless] = type == :method ? :unless_method : unless_proc
        end

        if value
          include_examples 'does not serialize the conditional field'
        else
          include_examples 'serializes the conditional field'
        end
      end
    end
  end

  context 'Given blueprint has ::view' do
    let(:identifier) do
      '{"id":' + obj_id + '}'
    end
    let(:no_view) do
      ['{"id":' + obj_id + '', '"first_name":"Meg"' + '}'].join(',')
    end
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
        field :first_name
        view :normal do
          field :position
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
      expect(blueprint.render(obj)).to                    eq(no_view)
      expect(blueprint.render(obj, view: :identifier)).to eq(identifier)
      expect(blueprint.render(obj, view: :normal)).to     eq(normal)
      expect(blueprint.render(obj, view: :extended)).to   eq(ext)
      expect(blueprint.render(obj, view: :special)).to    eq(special)
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

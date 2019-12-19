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

  context 'Given blueprint has ::field with all data types' do
    let(:result) { '{"active":false,"birthday":"1994-03-04","deleted_at":null,"first_name":"Meg","id":' + obj_id + '}' }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        field :id # number
        field :first_name # string
        field :active # boolean
        field :birthday # date
        field :deleted_at # null
      end
    end
    it('returns json with the correct values for each data type') { should eq(result) }
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

  context 'Given blueprint has ::fields with :datetime_format argument and global datetime_format' do
    before { Blueprinter.configure { |config| config.datetime_format = -> datetime { datetime.strftime("%s").to_i } } }
    after { reset_blueprinter_config! }

    let(:result) do
      '{"id":' + obj_id + ',"birthday":762739200,"deleted_at":null}'
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday
        field :deleted_at, datetime_format: '%FT%T%:z'
      end
    end
    it('returns json with a formatted field') { should eq(result) }
  end

  context 'Given blueprint has a string :datetime_format argument on an invalid ::field' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name, datetime_format: "%m/%d/%Y"
      end
    end
    it('raises an InvalidDateTimeFormatterError') { expect{subject}.to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError) }
  end

  context 'Given blueprint has ::field with a Proc :datetime_format argument' do
    let(:result) do
      '{"id":' + obj_id + ',"birthday":762739200,"deleted_at":null}'
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday,   datetime_format: -> datetime { datetime.strftime("%s").to_i }
        field :deleted_at, datetime_format: -> datetime { datetime.strftime("%s").to_i }
      end
    end
    it('returns json with a formatted field') { should eq(result) }
  end

  context 'Given blueprint has a Proc :datetime_format argument on an invalid ::field' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name, datetime_format: -> datetime { datetime.capitalize }
      end
    end
    it('raises an InvalidDateTimeFormatterError') { expect{subject}.to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError) }
  end

  context 'Given blueprint has a Proc :datetime_format which fails to process date' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday, datetime_format: -> datetime { datetime.invalid_method }
      end
    end
    it('raises original error from Proc') { expect{subject}.to raise_error(NoMethodError) }
  end

  context 'Given blueprint has ::field with an invalid :datetime_format argument' do
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :birthday, datetime_format: :invalid_symbol_format
      end
    end
    it('raises an InvalidDateTimeFormatterError') { expect{subject}.to raise_error(Blueprinter::DateTimeFormatter::InvalidDateTimeFormatterError) }
  end

  context "Given default_if option is Blueprinter::EMPTY_STRING" do
    before do
      obj[:first_name] = ""
      obj[:last_name] = ""
    end

    let(:result) { '{"first_name":"Unknown","id":' + obj_id + ',"last_name":null}' }
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        field :id
        field :first_name, default_if: Blueprinter::EMPTY_STRING, default: "Unknown"
        field :last_name, default_if: Blueprinter::EMPTY_STRING
      end
    end
    it('uses the correct default values') { should eq(result) }
  end

  context "Given blueprint has ::field with nil value" do
    before do
      obj[:first_name] = nil
    end

    context "Given global default field value is specified" do
      before { Blueprinter.configure { |config| config.field_default = "N/A" } }
      after { reset_blueprinter_config! }

      context "Given default field value is not provided" do
        let(:result) { '{"first_name":"N/A","id":' + obj_id + '}' }
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :id
            field :first_name
          end
        end
        it('global default value is rendered for nil field') { should eq(result) }
      end

      context "Given default field value is provided" do
        let(:result) { '{"first_name":"Unknown","id":' + obj_id + '}' }
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :id
            field :first_name, default: "Unknown"
          end
        end
        it('field-level default value is rendered for nil field') { should eq(result) }
      end

      context "Given default field value is provided but is nil" do
        let(:result) { '{"first_name":null,"id":' + obj_id + '}' }
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :id
            field :first_name, default: nil
          end
        end
        it('field-level default value is rendered for nil field') { should eq(result) }
      end
    end

    context "Given global default value is not specified" do
      context "Given default field value is not provided" do
        let(:result) { '{"first_name":null,"id":' + obj_id + '}' }
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :id
            field :first_name
          end
        end
        it('returns json with specified fields') { should eq(result) }
      end

      context "Given default field value is provided" do
        let(:result) { '{"first_name":"Unknown","id":' + obj_id + '}' }
        let(:blueprint) do
          Class.new(Blueprinter::Base) do
            field :id
            field :first_name, default: "Unknown"
          end
        end
        it('field-level default value is rendered for nil field') { should eq(result) }
      end
    end
  end

  context 'Given blueprint has ::field with a conditional argument' do
    context 'Given conditional proc has deprecated two argument signature' do
      before do
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      let(:if_proc) { ->(_obj, _local_opts) { true } }
      let(:unless_proc) { ->(_obj, _local_opts) { true } }

      let(:blueprint) do
        Class.new(Blueprinter::Base) do
          field :id
          field :first_name, if: ->(_obj, _local_opts) { true }
          field :last_name, unless: ->(_obj, _local_opts) { true }
        end
      end

      it('writes deprecation warning message to $stderr') do
        blueprint.render(obj, root: :root)
        $stderr.rewind
        stderr_output = $stderr.string.chomp
        expect(stderr_output).to include("[DEPRECATION] Blueprinter :if conditions now expects 3 arguments instead of 2.")
        expect(stderr_output).to include("[DEPRECATION] Blueprinter :unless conditions now expects 3 arguments instead of 2.")
      end

      after do
        $stderr = @orig_stderr
      end
    end

    context 'Given conditional proc has three argument signature' do
      variants = %i[proc method].product([true, false])

      let(:if_value) { true }
      let(:unless_value) { false }
      let(:field_options) { {} }
      let(:local_options) { { x: 1, y: 2 } }
      let(:if_proc) { ->(_field_name, _obj, _local_opts) { if_value } }
      let(:unless_proc) { ->(_field_name, _obj, _local_opts) { unless_value } }
      let(:blueprint) do
        f_options = field_options

        bp = Class.new(Blueprinter::Base) do
          field :id
          field :first_name, f_options
        end
        bp.instance_eval <<-RUBY, __FILE__, __LINE__ + 1
              def self.if_method(_field_name, _object, _options)
                #{if_value}
              end

              def self.unless_method(_field_name, _object, _options)
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
      '"last_name":"' + obj[:last_name] + '"', '"position":"Manager"}'].join(',')
    end
    let(:ext) do
      ['{"id":' + obj_id + '', '"description":"A person"', '"employer":"Procore"',
      '"first_name":"Meg"', '"position":"Manager"}'].join(',')
    end
    let(:special) do
      ['{"id":' + obj_id + '', '"description":"A person"',
      '"first_name":"Meg"}'].join(',')
    end
    let(:blueprint) do
      Class.new(Blueprinter::Base) do
        identifier :id
        field :first_name
        view :normal do
          fields :last_name, :position
          field :company, name: :employer
        end
        view :extended do
          include_view :normal
          field :description
          exclude :last_name
        end
        view :special do
          include_view :extended
          excludes :employer, :position
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

  context 'Given blueprint has :root' do
    let(:result) { '{"root":{"id":' + obj_id + ',"position_and_company":"Manager at Procore"}}' }
    let(:blueprint) { blueprint_with_block }
    it('returns json with a root') do
      expect(blueprint.render(obj, root: :root)).to eq(result)
    end
  end

  context 'Given blueprint has :meta' do
    let(:result) { '{"root":{"id":' + obj_id + ',"position_and_company":"Manager at Procore"},"meta":"meta_value"}' }
    let(:blueprint) { blueprint_with_block }
    it('returns json with a root') do
      expect(blueprint.render(obj, root: :root, meta: 'meta_value')).to eq(result)
    end
  end

  context 'Given blueprint has :meta without :root' do
    let(:blueprint) { blueprint_with_block }
    it('raises a BlueprinterError') {
      expect{blueprint.render(obj, meta: 'meta_value')}.to raise_error(Blueprinter::BlueprinterError)
    }
  end

  context 'Given blueprint has root as a non-supported object' do
    let(:blueprint) { blueprint_with_block }
    it('raises a BlueprinterError') {
      expect{blueprint.render(obj, root: {some_key: "invalid root"})}.to raise_error(Blueprinter::BlueprinterError)
    }
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

  context 'Given blueprint has a transformer' do
    subject { blueprint.render(obj) }
    let(:result) { '{"id":' + obj_id + ',"full_name":"Meg Ryan"}' }
    let(:blueprint) do
      DynamicFieldsTransformer = Class.new(Blueprinter::Transformer) do
        def transform(result_hash, object, options={})
          dynamic_fields = (object.is_a? Hash) ? object[:dynamic_fields] : object.dynamic_fields
          result_hash.merge!(dynamic_fields)
        end
      end
      Class.new(Blueprinter::Base) do
        identifier :id
        transform DynamicFieldsTransformer
      end
    end
    it('returns json with values derived from options') { should eq(result) }
  end
end

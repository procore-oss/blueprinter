module Blueprinter
  module Generators
    class InitializerGenerator < Rails::Generators::Base
      desc "Generates an initializer for Blueprinter"

      attr_accessor :options

      source_root File.expand_path("../templates", __FILE__)



      class_option :initializer_dir, default: "config/initializers", desc: "path to initializer file"

      class_option :name, default: "blueprinter.rb", desc: "name of initializer file"



      class_option :generator, default: "json", desc: "What gem to use for JSON", banner: "oj|yajl"

      class_option :method, default: nil, desc: "What method to call on the generator", banner: "encode"



      class_option :sort_fields_by, default: nil, desc: "How to sort JSON fields", banner: "definition"



      class_option :field_default, type: :string, default: nil, desc: "field_default config option", banner: "\"N/A\""

      class_option :association_default, type: :string, default: nil, desc: "association_default config option", banner: "{}", aliases: "-a"



      remove_class_option :skip_namespace

      def ensure_initializer_dir
        FileUtils.mkdir_p(options["initializer_dir"]) unless File.directory?(options["initializer_dir"])
      end

      def create_initializer
        template "initializer.rb", File.join(options["initializer_dir"], options["name"] )
      end

      private

      def generator_gem
        {json: "JSON", oj: "Oj", yajl: "Yajl::Encoder"}[options["generator"].intern]
      end

      def empty_string(default)
        default.to_s.gsub(/"'/,'').blank?
      end

    end
  end
end

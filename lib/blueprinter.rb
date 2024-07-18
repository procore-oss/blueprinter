# frozen_string_literal: true

module Blueprinter
  # Core
  autoload :Association, 'blueprinter/association'
  autoload :Base, 'blueprinter/base'
  autoload :Configuration, 'blueprinter/configuration'
  autoload :Deprecation, 'blueprinter/deprecation'
  autoload :Extension, 'blueprinter/extension'
  autoload :Extensions, 'blueprinter/extensions'
  autoload :Field, 'blueprinter/field'
  autoload :Reflection, 'blueprinter/reflection'
  autoload :View, 'blueprinter/view'
  autoload :ViewCollection, 'blueprinter/view_collection'

  # Extractors & Transfomers
  autoload :AssociationExtractor, 'blueprinter/extractors/association_extractor'
  autoload :AutoExtractor, 'blueprinter/extractors/auto_extractor'
  autoload :BlockExtractor, 'blueprinter/extractors/block_extractor'
  autoload :Extractor, 'blueprinter/extractor'
  autoload :HashExtractor, 'blueprinter/extractors/hash_extractor'
  autoload :PublicSendExtractor, 'blueprinter/extractors/public_send_extractor'
  autoload :Transformer, 'blueprinter/transformer'

  # Helpers & Types
  autoload :BaseHelpers, 'blueprinter/helpers/base_helpers'
  autoload :DateTimeFormatter, 'blueprinter/formatters/date_time_formatter'
  autoload :EmptyTypes, 'blueprinter/empty_types'
  autoload :TypeHelpers, 'blueprinter/helpers/type_helpers'

  # Errors & Validation
  autoload :BlueprinterError, 'blueprinter/blueprinter_error'
  autoload :BlueprintValidator, 'blueprinter/blueprint_validator'
  autoload :Errors, 'blueprinter/errors'

  extend Configuration::Configurable
end

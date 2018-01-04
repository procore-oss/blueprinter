require File.expand_path("../../spec/dummy/config/environment.rb", __FILE__)
Rails.env = 'test'
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../spec/dummy/db/migrate", __FILE__)]

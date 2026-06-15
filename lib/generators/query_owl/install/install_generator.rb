require "rails/generators"

module QueryOwl
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a QueryOwl initializer in config/initializers."

      def copy_initializer
        template "initializer.rb", "config/initializers/query_owl.rb"
      end
    end
  end
end

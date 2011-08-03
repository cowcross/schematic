module Schematic
  class InvalidClass < Exception
    def message
      "This class does not include ActiveModel. You cannot generate an XSD from it."
    end
  end
  module Generator
    autoload :Sandbox, 'schematic/generator/sandbox'
    autoload :Xsd, 'schematic/generator/xsd'
    autoload :Names, 'schematic/generator/names'
    autoload :Namespaces, 'schematic/generator/namespaces'
    autoload :Column, 'schematic/generator/column'
    autoload :ColumnValidator, 'schematic/generator/column_validator'
    autoload :Types, 'schematic/generator/types'
    autoload :Uniqueness, 'schematic/generator/uniqueness'

    module Restrictions
      autoload :Base, 'schematic/generator/restrictions/base'
      autoload :Custom, 'schematic/generator/restrictions/custom'
      autoload :Enumeration, 'schematic/generator/restrictions/enumeration'
      autoload :Length, 'schematic/generator/restrictions/length'
      autoload :Pattern, 'schematic/generator/restrictions/pattern'
      autoload :Numericality, 'schematic/generator/restrictions/numericality'
    end
  end
  module Serializers
    autoload :Xsd, 'schematic/serializers/xsd'
  end

  autoload :Version, 'schematic/version'
end

require "builder"
require 'active_support/inflector/inflections'
require 'active_support/inflections'

ActiveRecord::Base.send(:extend, Schematic::Serializers::Xsd)

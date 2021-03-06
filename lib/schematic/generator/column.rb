require 'active_model/validations/presence'
require 'schematic/generator/restrictions/custom'
require 'schematic/generator/restrictions/enumeration'
require 'schematic/generator/restrictions/length'
require 'schematic/generator/restrictions/numericality'
require 'schematic/generator/restrictions/pattern'

module Schematic
  module Generator
    class Column
      attr_accessor :restriction_classes

      def self.restriction_classes
        Restrictions::Base.descendants.freeze
      end

      def initialize(klass, column, additional_methods = {}, ignored_methods = {}, required_methods = [], non_required_methods = [])
        @klass = klass
        @column = column
        @additional_methods = additional_methods
        @ignored_methods = ignored_methods
        @required_methods = required_methods
        @non_required_methods = non_required_methods
      end

      def generate(builder)
        return if skip_generation?

        options = {
          'name' => @column.name.dasherize,
          'minOccurs' => minimum_occurrences_for_column.to_s,
          'maxOccurs' => '1'
        }
        options.merge!({'nillable' => 'false'}) if minimum_occurrences_for_column > 0

        builder.xs :element, options do |field|
          field.xs :complexType do |complex_type|
            complex_type.xs :simpleContent do |simple_content|
              simple_content.xs :restriction, 'base' => map_type(@column) do |restriction|
                self.class.restriction_classes.each do |restriction_class|
                  restriction_class.new(@klass, @column).generate(restriction)
                end
              end
            end
          end
        end
      end

      def minimum_occurrences_for_column
        return 0 if @non_required_methods.include?(@column.name.to_sym)
        return 1 if @required_methods.include?(@column.name.to_sym)
        return 0 unless @klass.respond_to?(:_validators)
        @klass._validators[@column.name.to_sym].each do |column_validation|
          next unless column_validation.is_a? ActiveModel::Validations::PresenceValidator
          if column_validation.options[:allow_blank] != true &&
            column_validation.options[:if].nil? &&
            column_validation.options[:unless].nil?

            return 1
          end
        end
        0
      end

      def map_type(column)
        Types::COMPLEX.fetch(column.type)[:complex_type]
      end

      def skip_generation?
        (@additional_methods.keys + @ignored_methods.keys).map(&:to_s).include?(@column.name)
      end
    end
  end
end

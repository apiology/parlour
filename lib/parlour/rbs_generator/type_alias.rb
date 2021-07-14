# typed: true
module Parlour
  class RbsGenerator < Generator
    # Represents a type alias.
    class TypeAlias < RbsObject
      sig do
        params(
          generator: Generator,
          name: String,
          type: Types::TypeLike,
          block: T.nilable(T.proc.params(x: TypeAlias).void)
        ).void
      end
      # Creates a new type alias.
      #
      # @param name [String] The name of the alias.
      # @param value [String] The type to alias to.
      def initialize(generator, name:, type:, &block)
        super(generator, name)
        @type = type
        yield_self(&block) if block
      end

      # @return [String] The type to alias to.
      sig { returns(Types::TypeLike) }
      attr_reader :type

      sig { params(other: Object).returns(T::Boolean) }
      # Returns true if this instance is equal to another type alias.
      #
      # @param other [Object] The other instance. If this is not a {TypeAlias} (or a
      #   subclass of it), this will always return false.
      # @return [Boolean]
      def ==(other)
        TypeAlias === other && name == other.name && type == other.type
      end

      sig do
        override.params(
          indent_level: Integer,
          options: Options
        ).returns(T::Array[String])
      end
      # Generates the RBS lines for this type alias.
      #
      # @param indent_level [Integer] The indentation level to generate the lines at.
      # @param options [Options] The formatting options to use.
      # @return [Array<String>] The RBS lines, formatted as specified.
      def generate_rbs(indent_level, options)
        [options.indented(indent_level,
          "type #{name} = #{String === @type ? @type : @type.generate_rbs}"
        )]
      end

      sig do
        override.params(
          others: T::Array[RbsGenerator::RbsObject]
        ).returns(T::Boolean)
      end
      # Given an array of {TypeAlias} instances, returns true if they may be 
      # merged into this instance using {merge_into_self}. This is always false.
      #
      # @param others [Array<RbiGenerator::RbsObject>] An array of other
      #   {TypeAlias} instances.
      # @return [Boolean] Whether this instance may be merged with them.
      def mergeable?(others)
        others.all? { |other| self == other }
      end

      sig do
        override.params(
          others: T::Array[RbsGenerator::RbsObject]
        ).void
      end
      # Given an array of {TypeAlias} instances, merges them into this one.
      # This particular implementation will simply do nothing, as instances
      # are only mergeable if they are indentical.
      # You MUST ensure that {mergeable?} is true for those instances.
      #
      # @param others [Array<RbiGenerator::RbsObject>] An array of other
      #   {TypeAlias} instances.
      # @return [void]
      def merge_into_self(others)
        # We don't need to change anything! We only merge identical type alias
      end

      sig { override.returns(T::Array[T.any(Symbol, Hash)]) }
      def describe_attrs
        [{type: type}] # avoid quotes
      end
    end
  end
end

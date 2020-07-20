# frozen_string_literal: true
# typed: true

module T::Types
  # Takes a list of types. Validates that an object matches at least one of the types.
  class Union < Base
    attr_reader :types

    def initialize(types)
      @types = types.flat_map do |type|
        type = T::Utils.resolve_alias(type)
        if type.is_a?(Union)
          # Simplify nested unions (mostly so `name` returns a nicer value)
          type.types
        else
          T::Utils.coerce(type)
        end
      end.uniq
    end

    # @override Base
    def name
      type_shortcuts(@types)
    end

    private def type_shortcuts(types)
      if types.size == 1
        return types[0].name
      end
      nilable = T::Utils.coerce(NilClass)
      trueclass = T::Utils.coerce(TrueClass)
      falseclass = T::Utils.coerce(FalseClass)
      if types.any? {|t| t == nilable}
        remaining_types = types.reject {|t| t == nilable}
        "T.nilable(#{type_shortcuts(remaining_types)})"
      elsif types.any? {|t| t == trueclass} && types.any? {|t| t == falseclass}
        remaining_types = types.reject {|t| t == trueclass || t == falseclass}
        type_shortcuts([T::Private::Types::StringHolder.new("T::Boolean")] + remaining_types)
      else
        names = types.map(&:name).compact.sort
        "T.any(#{names.join(', ')})"
      end
    end

    # @override Base
    def valid?(obj)
      @types.any? {|type| type.valid?(obj)}
    end

    # @override Base
    private def subtype_of_single?(other)
      raise "This should never be reached if you're going through `subtype_of?` (and you should be)"
    end

    module Private
      module Pool
        def self.union_of_types(type_a, type_b, *types)
          # We aren't guaranteed to detect a simple `T.nilable(<Module>)` type here
          # in cases where NilClass is in `*types`, or there are duplicate types,
          # or there are nested unions, etc. That's ok, because this is an optimization
          # which isn't necessary for correctness.
          if types.empty?
            if type_b == T::Utils::Nilable::NIL_TYPE && type_a.is_a?(T::Types::Simple)
              type_a.to_nilable
            elsif type_a == T::Utils::Nilable::NIL_TYPE && type_b.is_a?(T::Types::Simple)
              type_b.to_nilable
            else
              Union.new([type_a, type_b])
            end
          else
            Union.new([type_a, type_b] + types)
          end
        end
      end
    end
  end
end

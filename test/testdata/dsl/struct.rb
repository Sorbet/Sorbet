# typed: true
require_relative "../../t"

module Foo
    class Struct
    end
end

class NotStruct
    B = T.let(Foo::Struct.new, Foo::Struct)
    var = Struct.new(:foo)
end

class RealStruct
    A = Struct.new(:foo, :bar)
    KeywordInit = Struct.new(:foo, :bar, keyword_init: true)
end
class RealStructDesugar
    class A < Struct
        extend T::Sig
        def foo; end
        def bar; end
        def foo=(arg0); arg0; end
        def bar=(arg0); arg0; end
        sig {params(foo: BasicObject, bar: BasicObject).returns(A)}
        def self.new(foo=nil, bar=nil)
            T.cast(nil, A)
        end
    end
end

class TwoStructs
    A = Struct.new(:foo)
    B = Struct.new(:foo)
end

class AccidentallyStruct
    class Struct
    end

    # We do this in the dsl pass before we've typeAlias the constants
    A = Struct.new(:foo, :bar)
end

class MixinStruct
  module MyMixin
    def foo; end
  end

  MyStruct = Struct.new(:x) do
    include MyMixin
    self.new.x
    self.new.foo
  end

  MyKeywordInitStruct = Struct.new(:x, keyword_init: true) do
    include MyMixin
    self.new.x
    self.new.foo
    self.new(1, 2) # error: Too many arguments provided for method `MixinStruct::MyKeywordInitStruct::_InitializeModule#initialize`. Expected: `0`, got: `2`
    self.new(giberish: 1) # error: Unrecognized keyword argument `giberish` passed for method `MixinStruct::MyKeywordInitStruct::_InitializeModule#initialize`
  end

  MyKeywordInitStruct.new(1, 2) # error: Too many arguments provided for method `MixinStruct::MyKeywordInitStruct::_InitializeModule#initialize`. Expected: `0`, got: `2`
  MyKeywordInitStruct.new(giberish: 1) # error: Unrecognized keyword argument `giberish` passed for method `MixinStruct::MyKeywordInitStruct::_InitializeModule#initialize`
  MyStruct.new.x
  MyStruct.new.foo
end

class OverrideInitialize
  Reopen = Struct.new(:x)
  class Reopen
    def initialize(x, cats:)
      super(x)
    end
  end

  Block = Struct.new(:x) do
    def initialize(x, cats:)
      super(x)
    end
  end

  ReopenKeywordInit = Struct.new(:x, keyword_init: true)
  class ReopenKeywordInit
    def initialize(x, cats:)
      super(x: x)
    end
  end

  BlockKeywordInit = Struct.new(:x, keyword_init: true) do
    def initialize(x, cats:)
      super(x: x)
    end
  end
end

class BadUsages
  A = Struct.new # error: Not enough arguments provided for method `Struct#initialize`. Expected: `1+`, got: `0`
  B = Struct.new(giberish: 1) # error: `{giberish: Integer(1)}` does not match `T.any(Symbol, String)` for argument `arg0`
  C = Struct.new(keyword_init: true) # error: `{keyword_init: TrueClass}` does not match `T.any(Symbol, String)` for argument `arg0`
  local = true
  D = Struct.new(keyword_init: local) # error: `{keyword_init: TrueClass}` does not match `T.any(Symbol, String)` for argument `arg0`
  E = Struct.new(:a, keyword_init: local) # we run too early in to be able to support this
end

class Main
    def main
        a = Struct.new(:foo)
        # a.is_a?(Struct) is actually false, because `Struct.new` dynamically
        # allocates and returns a class object for this struct, but we don't
        # have a great way to model that statically in the case where the
        # result is assigned to a local variable, not a constant.
        T.assert_type!(a, Struct)
        T.assert_type!(a.new, Struct)
        T.assert_type!(a.new(2), Struct)

        T.assert_type!(RealStruct::A.new(2, 3), RealStruct::A)
        T.assert_type!(RealStruct::A.new(2), RealStruct::A)

        T.assert_type!(RealStruct::KeywordInit.new, RealStruct::KeywordInit)
        T.assert_type!(RealStruct::KeywordInit.new(foo: 1), RealStruct::KeywordInit)
        T.assert_type!(RealStruct::KeywordInit.new(foo: 2, bar: 3), RealStruct::KeywordInit)
        RealStruct::KeywordInit.new(1, 2) # error: Too many arguments provided for method `RealStruct::KeywordInit::_InitializeModule#initialize`. Expected: `0`, got: `2`

        T.assert_type!(RealStructDesugar::A.new(2, 3), RealStructDesugar::A)
    end
end
puts Main.new.main

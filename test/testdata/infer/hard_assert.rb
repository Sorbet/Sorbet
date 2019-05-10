# typed: true

module Kernel
  Sorbet.sig do
    params(
      predicate: BasicObject,
      msg: T.nilable(String),
      opts: T.untyped,
    )
    .returns(NilClass)
  end
  def hard_assert(predicate, msg=nil, **opts); end
end

class Main
    extend T::Sig

    sig {params(a: T.any(Integer, String)).returns(NilClass)}
    def basic(a)
        hard_assert(a.is_a?(String))
        T.assert_type!(a, String)
        nil
    end

    sig {params(a: T.any(String, NilClass)).returns(NilClass)}
    def not(a)
        hard_assert(!a.nil?)
        T.assert_type!(a, String)
        nil
    end

    sig {params(a: T.any(String, NilClass)).returns(NilClass)}
    def with_and(a)
        hard_assert(a.nil? && 1 == 1)
        T.assert_type!(a, NilClass)
        nil
    end

    def with_storytime
        hard_assert(false, storytime: 42) # error: Hard assert is always false
    end
end

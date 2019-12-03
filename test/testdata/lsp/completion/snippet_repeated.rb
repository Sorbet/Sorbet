# typed: true
class A
  extend T::Sig

  sig {params(x: T.untyped).void}
  def method_using_kwarg(**x)
  end

  sig {params(x: T.untyped).void}
  def method_using_rest_arg(*x)
  end
end

A.new.method_using_kwar # error: does not exist
#                      ^ apply-completion: [A] item: 0

A.new.method_using_rest_ar # error: does not exist
#                         ^ apply-completion: [B] item: 0

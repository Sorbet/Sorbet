# typed: strict
extend T::Sig

module Boolean
  extend T::Helpers
  sealed!
end

class FalseClass
  include Boolean
end

class TrueClass
  include Boolean
end

sig {params(x: Boolean).void}
def foo(x)
  case x
  when TrueClass
    T.reveal_type(x)
  else
    T.absurd(x) # error: Control flow reached `T.absurd` because the type `FalseClass` wasn't handled
  end
end

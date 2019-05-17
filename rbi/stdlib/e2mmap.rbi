# typed: core

module Exception2MessageMapper
  sig {params(err: Exception, rest: T.untyped).void}
  def Raise(err, *rest); end

  sig {params(err: Exception, rest: T.untyped).void}
  def fail(err, *rest); end

  sig {params(err: Exception, rest: T.untyped).void}
  def Fail(err, *rest); end

  sig {params(c: Class, m: String).void}
  def def_e2message(c, m); end

  sig {params(n: Symbol, m: String, s: Class).void}
  def def_exception(n, m, s = StandardError); end
end

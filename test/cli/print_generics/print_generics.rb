# typed: strict

extend T::Sig

def foo(x)
  T::Array[Integer].new
end

def bar(x)
  T::Hash[Symbol, Integer].new
end

def qux(x)
  T::Enumerable[Integer].new
end

def wub(x)
  T::Range[Integer].new(0, 10)
end

def zan(x)
  T::Set[Integer].new
end

def gaz(x)
  T::Enumerator[Integer].new {|x| x << 1}
end

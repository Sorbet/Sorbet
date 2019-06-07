---
id: stdlib-generics
title: Arrays, Hashes, and Generics in the Standard Library
sidebar_label: Arrays & Hashes
---

> TODO: This page is still a fragment. Contributions welcome!

Sorbet supports generics types. The syntax looks likes `MyClass[Elem]`. For user defined generic classes, it's possible
to make this valid Ruby syntax.

However, it's not possible to change the syntax for classes in the Ruby standard library that should be generic. To make
up for this, we use wrappers in the `T` namespace to represent them:

- `T::Array[Type]`
- `T::Hash[KeyType, ValueType]`
- `T::Set[Type]`
- `T::Enumerable[Type]`
- `T::Range[Type]`

While you still can write `Array` or `Hash` inside a sig, they will be treated as `T::Array[T.untyped]` and
`T::Hash[T.untyped, T.untyped]` respectively.

```ruby
# typed: true
extend T::Sig

sig { returns(Array) }
def foo
  [1, "heh"]
end

T.reveal_type(foo.first) # Revealed type: T.untyped

sig { returns(T::Array[T.any(Integer, String)]) }
def bar
  [1, "heh"]
end

T.reveal_type(bar.first) # Revealed type: T.nilable(T.any(Integer, String))
```

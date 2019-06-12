---
id: strict
title: Strict Mode
---

As introduced in [Enabling Static Checks](static.md), Sorbet has multiple
strictness modes. The default is `# typed: false`, which silences all type
errors. Next up is `# typed: true`, where type errors are reported. There's also
`# typed: strict`, which is a way to require that everything which needs an
annotation gets an annotation.

Specifically, in a `# typed: strict` file it's an error to omit type annotations
for:

- methods
- instance variables
- class variables
- constants
- block parameters

> Why is this not an error in `# typed: true`? In that strictness level,
> unannotated methods, instance variables, and constants are assumed to be
> `T.untyped`.

Files at `# typed: strict` will also raise a few other errors that
didn't show up before:

- Any use of `undef` produces an error.
- Using `yield` when you don't include a named block parameter in your
  argument list produces an error.
- Redundant casting operations, such as using `T.cast` to cast a value
  to a type that it is already known to be, or using `T.must` on a
  value already known to be non-`nil`, produce errors.


## Annotating Constants

Sorbet does not, by default, infer the types of constants, but you can specify
them using T.let:

```ruby
NAMES = T.let(["Nelson", "Dmitry", "Paul"], T::Array[String])
```

## Declaring Class and Instance Variables

Declare an instance variable using `T.let` in a class's constructor:

```ruby
class MyObj
  def initialize
    @foo = T.let(0, Integer)
  end
end
```

We can also declare class variables and instance variables on a singleton class
using `T.let` outside of any method:

```ruby
class HasVariables
  # Class variable
  @@llamas = T.let([], T::Array[Llama])

  # Instance variable on the singleton class
  @alpaca_count = T.let(0, Integer)
end
```

## Annotating Block Parameters

Ruby allows you to write methods that take a block parameter without
naming that parameter by using `yield` in the body of the method. At
`# typed: strict`, Sorbet will force you to give that parameter a name
even if you're using `yield`. For example, Sorbet will **reject** the
following code snippet because the method uses `yield` but has not
named its block parameter, which in turn means that it lacks a
declared type:

```ruby
# typed: strict
sig { void }
def call_twice  # error: Method call_twice uses yield but does not mention a block parameter
  yield
  yield
end
```

You don't need to refactor your method body to use `block.call` to fix
this problem: you can give the method a named block parameter like
`&blk`, and `yield` will automatically invoke the `blk`
parameter. This also means that you must give a type to that block
parameter when you're using `# typed: strict`:

```ruby
# typed: strict
sig { params(blk: T.proc.void).void }
def call_twice(&blk)
  yield
  yield
end
```

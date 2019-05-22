# These are extensions to the Ruby language that we added to make the type systems easier
# typed: __STDLIB_INTERNAL

class Struct
  sig do
    params(
        arg0: T.any(Symbol, String),
        arg1: T.any(Symbol, String),
        keyword_init: T::Boolean,
    )
    .void
  end
  def initialize(arg0, *arg1, keyword_init: false); end

  sig do
    params(
        blk: T.proc.params(arg0: Elem).returns(BasicObject),
    )
    .returns(T.untyped)
  end
  sig {returns(T.self_type)}
  def each(&blk); end

  sig {returns(T::Array[Symbol])}
  def self.members; end

  sig {params(args: T.untyped).returns(Struct)}
  def new(*args); end
end

# Type alias for file-like objects. Many, but not all, file-like
# types in the Ruby stdlib are descendants of IO. These include
# pipes and sockets. These descendants are intentionally omitted
# here.
::Sorbet::Private::Static::IOLike = T.type_alias(
  T.any(
    IO,
    StringIO,
    Tempfile
  )
)

# typed: true

module Mixin; end
class Foo
    include Mixin;
end

class Main
    extend T::Sig

    sig {params(a: T.class_of(Mixin)).returns(T.class_of(Mixin))}
    def bar(a)
        a
    end

    def main
        bar(Mixin)
        bar(Foo) # error: `T.class_of(Foo)` does not match `T.class_of(Mixin)` for argument `a`
                 # TODO: RUBYPLAT-504
    end
end

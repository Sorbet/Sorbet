# typed: true

class Module
  include T::Sig
end

class A
  sig # error: no block
  #  ^ apply-completion: [A] item: 0
  def self.foo
    1
  end
end

sig # error: no block
#  ^ apply-completion: [B] item: 0
def self.main
  ''
end

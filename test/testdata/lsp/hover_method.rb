# typed: true
class Foo
  extend T::Sig

  sig {returns(Integer)}
  def bar
    # ^ hover: returns(Integer)
    # N.B. Checking two positions on below function call as they used to return different strings.
    baz("1")
  # ^ hover: params(arg0: String).returns(Integer)
   # ^ hover: params(arg0: String).returns(Integer)
   self.baz("1")
      # ^ hover: params(arg0: String).returns(Integer)
  end

  sig {params(arg0: String).returns(Integer)}
  def baz(arg0)
    no_args_and_void
  # ^ hover: void
    Foo::bat(1)
  # ^ hover: Foo
       # ^ hover: params(i: Integer).returns(Integer)
           # ^ hover: Integer(1)
    arg0.to_i
  end

  sig {params(i: Integer).returns(Integer)}
  def self.bat(i)
    10
  end

  sig {void}
  def no_args_and_void

  end
end

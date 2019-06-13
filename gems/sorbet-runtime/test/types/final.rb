# frozen_string_literal: true
require_relative '../test_helper'

class Opus::Types::Test::AbstractValidationTest < Critic::Unit::UnitTest
  it "allows declaring a class as final" do
    c = Class.new do
      extend T::Helpers
      final!
      def foo; 3; end
    end
    assert_equal(c.new.foo, 3)
  end

  it "forbids declaring a module as final" do
    err = assert_raises(RuntimeError) do
      Module.new do
        extend T::Helpers
        final!
      end
    end
    assert_includes(err.message, "is not a class, but was declared final")
  end

  it "forbids re-declaring a class as final" do
    err = assert_raises(RuntimeError) do
      Class.new do
        extend T::Helpers
        final!
        final!
      end
    end
    assert_includes(err.message, "was already declared as final")
  end

  it "forbids subclassing a final class" do
    c = Class.new do
      extend T::Helpers
      final!
    end
    err = assert_raises(RuntimeError) do
      Class.new(c)
    end
    assert_includes(err.message, "was declared final and cannot be subclassed")
  end
end

# typed: __STDLIB_INTERNAL

# This library provides three different ways to delegate method calls to an
# object. The easiest to use is
# [`SimpleDelegator`](https://docs.ruby-lang.org/en/2.6.0/SimpleDelegator.html).
# Pass an object to the constructor and all methods supported by the object will
# be delegated. This object can be changed later.
#
# Going a step further, the top level DelegateClass method allows you to easily
# setup delegation through class inheritance. This is considerably more flexible
# and thus probably the most common use for this library.
#
# Finally, if you need full control over the delegation scheme, you can inherit
# from the abstract class
# [`Delegator`](https://docs.ruby-lang.org/en/2.6.0/Delegator.html) and
# customize as needed. (If you find yourself needing this control, have a look
# at [`Forwardable`](https://docs.ruby-lang.org/en/2.6.0/Forwardable.html) which
# is also in the standard library. It may suit your needs better.)
#
# SimpleDelegator's implementation serves as a nice example of the use of
# Delegator:
#
# ```ruby
# class SimpleDelegator < Delegator
#   def __getobj__
#     @delegate_sd_obj # return object we are delegating to, required
#   end
#
#   def __setobj__(obj)
#     @delegate_sd_obj = obj # change delegation object,
#                            # a feature we're providing
#   end
# end
# ```
#
# ## Notes
#
# Be advised, [`RDoc`](https://docs.ruby-lang.org/en/2.6.0/RDoc.html) will not
# detect delegated methods.
class Delegator < BasicObject
end

# A concrete implementation of
# [`Delegator`](https://docs.ruby-lang.org/en/2.6.0/Delegator.html), this class
# provides the means to delegate all supported method calls to the object passed
# into the constructor and even to change the object being delegated to at a
# later time with #\_\_setobj\_\_.
#
# ```ruby
# class User
#   def born_on
#     Date.new(1989, 9, 10)
#   end
# end
#
# class UserDecorator < SimpleDelegator
#   def birth_year
#     born_on.year
#   end
# end
#
# decorated_user = UserDecorator.new(User.new)
# decorated_user.birth_year  #=> 1989
# decorated_user.__getobj__  #=> #<User: ...>
# ```
#
# A
# [`SimpleDelegator`](https://docs.ruby-lang.org/en/2.6.0/SimpleDelegator.html)
# instance can take advantage of the fact that
# [`SimpleDelegator`](https://docs.ruby-lang.org/en/2.6.0/SimpleDelegator.html)
# is a subclass of `Delegator` to call `super` to have methods called on the
# object being delegated to.
#
# ```ruby
# class SuperArray < SimpleDelegator
#   def [](*args)
#     super + 1
#   end
# end
#
# SuperArray.new([1])[0]  #=> 2
# ```
#
# Here's a simple example that takes advantage of the fact that
# SimpleDelegator's delegation object can be changed at any time.
#
# ```ruby
# class Stats
#   def initialize
#     @source = SimpleDelegator.new([])
#   end
#
#   def stats(records)
#     @source.__setobj__(records)
#
#     "Elements:  #{@source.size}\n" +
#     " Non-Nil:  #{@source.compact.size}\n" +
#     "  Unique:  #{@source.uniq.size}\n"
#   end
# end
#
# s = Stats.new
# puts s.stats(%w{James Edward Gray II})
# puts
# puts s.stats([1, 2, 3, nil, 4, 5, 1, 2])
# ```
#
# Prints:
#
# ```
# Elements:  4
#  Non-Nil:  4
#   Unique:  4
#
# Elements:  8
#  Non-Nil:  7
#   Unique:  6
# ```
class SimpleDelegator < Delegator
end

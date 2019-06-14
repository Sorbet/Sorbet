# typed: __STDLIB_INTERNAL

class Thread < Object
  sig {returns(Thread)}
  def self.current; end

  sig {returns(Thread)}
  def self.main; end

  sig {params(key: T.any(String, Symbol)).returns(T.untyped)}
  def [](key); end

  sig {params(key: T.any(String, Symbol), value: T.untyped).returns(T.untyped)}
  def []=(key, value); end

  sig {returns(T::Boolean)}
  def alive?; end

  sig {returns(T.nilable(Thread))}
  def kill; end
end

class Thread::Backtrace < Object
end

class Thread::Backtrace::Location
  sig {returns(T.nilable(String))}
  def absolute_path(); end

  sig {returns(T.nilable(String))}
  def base_label(); end

  sig {returns(T.nilable(String))}
  def label(); end

  sig {returns(Integer)}
  def lineno(); end

  sig {returns(T.nilable(String))}
  def path(); end
end

class Thread::ConditionVariable < Object
end

class Thread::Mutex < Object
end

class Thread::Queue < Object
end

class Thread::SizedQueue < Thread::Queue
end

class ClosedQueueError < StopIteration
end

class ThreadError < StandardError
end

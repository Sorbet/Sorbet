# typed: core
class RubyVM < Object
  DEFAULT_PARAMS = T.let(T.unsafe(nil), Hash)
  INSTRUCTION_NAMES = T.let(T.unsafe(nil), Array)
  OPTS = T.let(T.unsafe(nil), Array)
end

class RubyVM::InstructionSequence < Object
end

class UncaughtThrowError < ArgumentError
end

# frozen_string_literal: true
# typed: true

class T::Private::DeclState
  def self.current
    Thread.current[:opus_types__decl_state] ||= self.new
  end

  def self.current=(other)
    Thread.current[:opus_types__decl_state] = other
  end

  attr_accessor :active_declaration
  attr_accessor :skip_next_on_method_added

  def reset!
    self.active_declaration = nil
  end
end

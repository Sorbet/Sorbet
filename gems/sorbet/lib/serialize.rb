# frozen_string_literal: true
# typed: true

require 'bigdecimal'

class Sorbet::Private::Serialize
  BLACKLIST_CONSTANTS = [
    ['DidYouMean', :NameErrorCheckers], # https://github.com/yuki24/did_you_mean/commit/b72fdbe194401f1be21f8ad7b6e3f784a0ad197d
    ['Net', :OpenSSL], # https://github.com/yuki24/did_you_mean/commit/b72fdbe194401f1be21f8ad7b6e3f784a0ad197d
  ]

  SPECIAL_METHOD_NAMES = %w[! ~ +@ ** -@ * / % + - << >> & | ^ < <= => > >= == === != =~ !~ <=> [] []= `]

  def constant_cache
    @constant_cache ||= Sorbet::Private::ConstantLookupCache.new
    @constant_cache
  end

  private def get_constants(mod, inherited=nil)
    @real_constants ||= Module.instance_method(:constants)
    if inherited.nil?
      @real_constants.bind(mod).call
    else
      @real_constants.bind(mod).call(inherited)
    end
  end

  def self.header(typed="true", subcommand="update")
    buffer = []
    buffer << "# This file is autogenerated. Do not edit it by hand. Regenerate it with:"
    buffer << "#   srb rbi #{subcommand}"
    if typed
      buffer << ""
      buffer << "# typed: #{typed}"
    end
    buffer << ""
    buffer.join("\n")
  end

  def class_or_module(class_name)
    if !valid_class_name(class_name)
      return " # Skipping serializing #{class_name} because it is an invalid name\n"
    end

    klass = constant_cache.class_by_name(class_name)
    is_nil = nil.equal?(klass)
    raise "#{class_name} is not a Class or Module. Maybe it was miscategorized?" if is_nil

    ret = String.new

    superclass = klass.is_a?(Class) ? klass.superclass : nil
    if superclass
      superclass_str = superclass == Object ? '' : constant_cache.name_by_class(superclass)
    else
      superclass_str = ''
    end
    superclass_str = !superclass_str || superclass_str.empty? ? '' : " < #{superclass_str}"
    ret << (klass.is_a?(Class) ? "class #{class_name}#{superclass_str}\n" : "module #{class_name}\n")
    ret << " extend T::Sig\n"

    # We don't use .included_modules since that also has all the aweful things
    # that are mixed into Object. This way we at least have a delimiter before
    # the awefulness starts (the superclass).
    klass.ancestors.each do |ancestor|
      next if ancestor == klass
      break if ancestor == superclass
      ancestor_name = constant_cache.name_by_class(ancestor)
      next unless ancestor_name
      next if ancestor_name == class_name
      if ancestor.is_a?(Class)
        ret << "  # Skipping `include #{ancestor_name}` because it is a Class\n"
        next
      end
      if !valid_class_name(ancestor_name)
        ret << "  # Skipping `include #{ancestor_name}` because it is an invalid name\n"
        next
      end
      ret << "  include ::#{ancestor_name}\n"
    end
    klass.singleton_class.ancestors.each do |ancestor|
      next if ancestor == klass.singleton_class
      break if ancestor == superclass&.singleton_class
      break if ancestor == Module
      break if ancestor == Object
      ancestor_name = constant_cache.name_by_class(ancestor)
      next unless ancestor_name
      if ancestor.is_a?(Class)
        ret << "  # Skipping `extend #{ancestor_name}` because it is a Class\n"
        next
      end
      if !valid_class_name(ancestor_name)
        ret << "  # Skipping `extend #{ancestor_name}` because it is an invalid name\n"
        next
      end
      ret << "  extend ::#{ancestor_name}\n"
    end

    constants = []
    # Declare all the type_members and type_templates
    constants += get_constants(klass).uniq.map do |const_sym|
      # We have to not pass `false` because `klass.constants` intentionally is
      # pulling in all the ancestor constants
      next if Sorbet::Private::ConstantLookupCache::DEPRECATED_CONSTANTS.include?("#{class_name}::#{const_sym}")
      begin
        value = klass.const_get(const_sym)
      rescue LoadError, NameError, RuntimeError
        ret << "# Failed to load #{class_name}::#{const_sym}\n"
        next
      end
      # next if !Sorbet::Private::RealStdlib.real_is_a?(value, T::Types::TypeVariable)
      next if Sorbet::Private::RealStdlib.real_is_a?(value, Module)
      next if !comparable?(value)
      [const_sym, value]
    end
    constants += get_constants(klass, false).uniq.map do |const_sym|
      next if BLACKLIST_CONSTANTS.include?([class_name, const_sym])
      next if Sorbet::Private::ConstantLookupCache::DEPRECATED_CONSTANTS.include?("#{class_name}::#{const_sym}")
      begin
        value = klass.const_get(const_sym, false)
      rescue LoadError, NameError, RuntimeError
        ret << "# Failed to load #{class_name}::#{const_sym}\n"
        next
      end
      next if Sorbet::Private::RealStdlib.real_is_a?(value, Module)
      next if !comparable?(value)
      [const_sym, value]
    end
    constants_serialized = constants.compact.sort.uniq.map do |const_sym, value|
      constant(const_sym, value)
    end
    ret << constants_serialized.join("\n")
    ret << "\n\n" if !constants_serialized.empty?

    methods = []
    instance_methods = klass.instance_methods(false)
    begin
      initialize = klass.instance_method(:initialize)
    rescue
      initialize = nil
    end
    if initialize && initialize.owner == klass
      # This method never apears in the reflection list...
      instance_methods += [:initialize]
    end
    klass.ancestors.reject {|ancestor| constant_cache.name_by_class(ancestor)}.each do |ancestor|
      instance_methods += ancestor.instance_methods(false)
    end

    # uniq here is required because we populate additional methos from anonymous superclasses and there
    # might be duplicates
    methods += instance_methods.sort.uniq.map do |method_sym|
      begin
        method = klass.instance_method(method_sym)
      rescue => e
        ret << "# #{e}\n"
        next
      end
      next if blacklisted_method(method)
      next if ancestor_has_method(method, klass)
      serialize_method(method)
    end
    # uniq is not required here, but added to be on the safe side
    methods += klass.singleton_methods(false).sort.uniq.map do |method_sym|
      begin
        method = klass.singleton_method(method_sym)
      rescue => e
        ret << "# #{e}\n"
        next
      end
      next if blacklisted_method(method)
      next if ancestor_has_method(method, klass.singleton_class)
      serialize_method(method, true)
    end
    ret << methods.join("\n")
    ret << "end\n"

    ret
  end

  def alias(base, other_name)
    ret = String.new
    ret << "#{other_name} = #{base}"
    ret
  end

  def comparable?(value)
    return false if Sorbet::Private::RealStdlib.real_is_a?(value, BigDecimal) && value.nan?
    return false if Sorbet::Private::RealStdlib.real_is_a?(value, Float) && value.nan?
    return false if Sorbet::Private::RealStdlib.real_is_a?(value, Complex)
    true
  end

  def blacklisted_method(method)
    method.name =~ /__validator__[0-9]{8}/ || method.name =~ /.*:.*/
  end

  def valid_method_name(name)
    return true if SPECIAL_METHOD_NAMES.include?(name)
    name =~ /^[[:word:]]+[?!=]?$/
  end

  def ancestor_has_method(method, klass)
    return false if !klass.is_a?(Class)
    ancestor = klass.ancestors.find do |ancestor|
      next if ancestor == klass
      begin
        ancestor.instance_method(method.name)
      rescue NameError
        nil
      end
    end
    return false unless ancestor
    ancestor.instance_method(method.name).parameters == method.parameters
  end

  def constant(const, value)
    #if Sorbet::Private::RealStdlib.real_is_a?(value, T::Types::TypeTemplate)
      #"  #{const} = type_template"
    #elsif Sorbet::Private::RealStdlib.real_is_a?(value, T::Types::TypeMember)
      #"  #{const} = type_member"
    #else
      #"  #{const} = ::T.let(nil, ::T.untyped)"
    #end
    if KEYWORDS.include?(const.to_sym)
      return "# Illegal constant name: #{const}"
    end
    "  #{const} = ::T.let(nil, ::T.untyped)"
  end

  def serialize_method(method, static=false, with_sig: true)
    name = method.name.to_s
    ret = String.new
    if !valid_method_name(name)
      ret << "# Illegal method name: #{name}"
      return
    end
    parameters = from_method(method)
    ret << serialize_sig(parameters) if with_sig
    args = parameters.map do |(kind, param_name)|
      to_sig(kind, param_name)
    end.compact.join(', ')
    ret << "  def #{static ? 'self.' : ''}#{name}(#{args}); end\n"
    ret
  end

  def valid_class_name(name)
    name.split("::").each do |piece|
      return false if piece[0].upcase != piece[0]
    end
    return false if [
      'Sorbet::Private::RbiGenerator::ClassOverride',
      'Sorbet::Private::RbiGenerator::ModuleOverride',
      'Sorbet::Private::RbiGenerator::ObjectOverride',
    ].include?(name)
    true
  end

  def serialize_sig(parameters)
    ret = String.new
    if !parameters.empty?
      ret << "  sig do\n"
      ret << "    params(\n"
      parameters.each do |(_kind, name)|
        ret << "      #{name}: ::T.untyped,\n"
      end
      ret << "    )\n"
      ret << "    .returns(::T.untyped)\n"
      ret << "  end\n"
    else
      ret << "  sig {returns(::T.untyped)}\n"
    end
    ret
  end

  # from https://docs.ruby-lang.org/en/2.4.0/keywords_rdoc.html
  KEYWORDS = [
    :__ENCODING__,
    :__LINE__,
    :__FILE__,
    :BEGIN,
    :END,
    :alias,
    :and,
    :begin,
    :break,
    :case,
    :class,
    :def,
    :defined?,
    :do,
    :else,
    :elsif,
    :end,
    :ensure,
    :false,
    :for,
    :if,
    :in,
    :module,
    :next,
    :nil,
    :not,
    :or,
    :redo,
    :rescue,
    :retry,
    :return,
    :self,
    :super,
    :then,
    :true,
    :undef,
    :unless,
    :until,
    :when,
    :while,
    :yield,
  ]

  def from_method(method)
    uniq = 0
    method.parameters.map.with_index do |(kind, name), index|
      if !name
        arg_name = method.name.to_s[0...-1]
        if (!KEYWORDS.include?(arg_name.to_sym)) && method.name.to_s.end_with?('=') && arg_name =~ /\A[a-z_][a-z0-9A-Z_]*\Z/ && index == 0
          name = arg_name
        else
          name = '_' + (uniq == 0 ? '' : uniq.to_s)
          uniq += 1
        end
      end
      [kind, name]
    end
  end

  def to_sig(kind, name)
    case kind
    when :req
      name.to_s
    when :opt
      "#{name}=T.unsafe(nil)"
    when :rest
      "*#{name}"
    when :keyreq
      "#{name}:"
    when :key
      "#{name}: T.unsafe(nil)"
    when :keyrest
      "**#{name}"
    when :block
      "&#{name}"
    end
  end
end

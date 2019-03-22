#!/usr/bin/env ruby

# frozen_string_literal: true
# typed: true

module SorbetRBIGeneration; end

require_relative './sorbet'
require_relative './require_everything'

require 'set'

alias DelegateClass_without_rbi_generator DelegateClass
def DelegateClass(superclass)
  result = DelegateClass_without_rbi_generator(superclass)
  SorbetRBIGeneration::Tracer.register_delegate_class(superclass, result)
  result
end

class SorbetRBIGeneration::Module
  @real_is_a = Module.instance_method(:is_a?)
  @real_name = Module.instance_method(:name)
  @real_object_id = Module.instance_method(:object_id)

  def self.real_is_a?(klass, type)
    @real_is_a.bind(klass).call(type)
  end

  def self.real_name(klass)
    @real_name.bind(klass).call
  end

  def self.real_object_id(klass)
    @real_object_id.bind(klass).call
  end
end

class SorbetRBIGeneration::Tracer
  module ModuleOverride
    def include(mod, *smth)
      result = super
      SorbetRBIGeneration::Tracer.module_included(mod, self)
      result
    end
  end
  Module.prepend(ModuleOverride)

  module ObjectOverride
    def extend(mod, *args)
      result = super
      SorbetRBIGeneration::Tracer.module_extended(mod, self)
      result
    end
  end
  Object.prepend(ObjectOverride)

  module ClassOverride
    def new(*)
      result = super
      SorbetRBIGeneration::Tracer.module_created(result)
      result
    end
  end
  Class.prepend(ClassOverride)

  def self.register_delegate_class(klass, delegate)
    @delegate_classes[SorbetRBIGeneration::Module.real_object_id(delegate)] = klass
  end

  def self.module_created(mod)
    add_to_context(type: :module, module: mod)
  end

  def self.module_included(included, includer)
    add_to_context(type: :include, module: includer, include: included)
  end

  def self.module_extended(extended, extender)
    add_to_context(type: :extend, module: extender, extend: extended)
  end

  def self.method_added(mod, method, singleton)
    add_to_context(type: :method, module: mod, method: method, singleton: singleton)
  end

  def self.trace
    start
    yield
    finish
    trace_results
  end

  def self.start
    pre_cache_module_methods
    install_tracepoints
  end

  def self.finish
    disable_tracepoints
  end

  def self.trace_results
    {
      files: @files,
      delegate_classes: @delegate_classes
    }
  end

  private

  @modules = {}
  @context_stack = [[]]
  @files = {}
  @delegate_classes = {}

  def self.pre_cache_module_methods
    ObjectSpace.each_object(Module) do |mod_|
      mod = T.cast(mod_, Module)
      @modules[SorbetRBIGeneration::Module.real_object_id(mod)] = (mod.instance_methods(false) + mod.private_instance_methods(false)).to_set
    end
  end

  def self.add_to_context(item)
    # The stack can be empty because we start the :c_return TracePoint inside a 'require' call.
    # In this case, it's okay to simply add something to the stack; it will be popped off when
    # the :c_return is traced.
    @context_stack << [] if @context_stack.empty?
    @context_stack.last << item
  end

  def self.install_tracepoints
    @class_tracepoint = TracePoint.new(:class) do |tp|
      module_created(tp.self)
    end
    @c_call_tracepoint = TracePoint.new(:c_call) do |tp|
      case tp.method_id
      when :require, :require_relative
        @context_stack << []
      end
    end
    @c_return_tracepoint = TracePoint.new(:c_return) do |tp|
      case tp.method_id
      when :require, :require_relative
        popped = @context_stack.pop

        next if popped.empty?

        path = $LOADED_FEATURES.last
        if tp.return_value != true # intentional true check
          next if popped.size == 1 && popped[0][:module].is_a?(LoadError)
          warn("Unexpected: constants or methods were defined when #{tp.method_id} didn't return true; adding to #{path} instead")
        end

        # raise 'Unexpected: constants or methods were defined without a file added to $LOADED_FEATURES' if path.nil?
        # raise "Unexpected: #{path} is already defined in files" if files.key?(path)

        @files[path] ||= []
        @files[path] += popped

        # popped.each { |item| item[:path] = path }
      when :method_added, :singleton_method_added
        begin
          tp.disable

          singleton = tp.method_id == :singleton_method_added
          receiver = singleton ? tp.self.singleton_class : tp.self
          methods = receiver.instance_methods(false) + receiver.private_instance_methods(false)
          set = @modules[SorbetRBIGeneration::Module.real_object_id(receiver)] ||= Set.new
          added = methods.find { |m| !set.include?(m) }
          if added.nil?
            # warn("Warning: could not find method added to #{tp.self} at #{tp.path}:#{tp.lineno}")
            next
          end
          set << added

          method_added(tp.self, added, singleton)
        ensure
          tp.enable
        end
      end
    end
    @class_tracepoint.enable
    @c_call_tracepoint.enable
    @c_return_tracepoint.enable
  end

  def self.disable_tracepoints
    @class_tracepoint.disable
    @c_call_tracepoint.disable
    @c_return_tracepoint.disable
  end

end

class SorbetRBIGeneration::RbiSerializer
  SPECIAL_METHOD_NAMES = %w[! ~ +@ ** -@ * / % + - << >> & | ^ < <= => > >= == === != =~ !~ <=> [] []= `]

  # These methods don't match the signatures of their parents, so if we let
  # them monkeypatch, they won't be subtypes anymore. Just don't support the
  # bad monkeypatches.
  BAD_METHODS = [
    ['activesupport', 'Time', :to_s],
    ['activesupport', 'Time', :initialize],
  ]

  def initialize(trace_results)
    @files = trace_results[:files]
    @delegate_classes = trace_results[:delegate_classes]

    @anonymous_map = {}
    @prev_anonymous_id = 0

  end

  def serialize(output_dir)
    grouped = {}
    used = {} # subclassed, included, or extended
    @files.each do |path, defined|
      gem = gem_from_location(path)
      if gem.nil?
        warn("Can't find gem for #{path}")
        next
      end
      next if gem[:gem] == 'ruby'

      grouped[gem] ||= {}
      defined.each do |item|
        klass = item[:module]
        klass_id = SorbetRBIGeneration::Module.real_object_id(klass)
        values = grouped[gem][klass_id] ||= []
        values << item unless item[:type] == :module

        # only add an anon module if it's used as a superclass of a non-anon module, or is included/extended by a non-anon module
        used_value = SorbetRBIGeneration::Module.real_is_a?(klass, Module) && !SorbetRBIGeneration::Module.real_name(klass).nil? ? true : SorbetRBIGeneration::Module.real_object_id(klass) # if non-anon, set it to true, otherwise link to next anon class
        (used[SorbetRBIGeneration::Module.real_object_id(klass.superclass)] ||= Set.new) << used_value if SorbetRBIGeneration::Module.real_is_a?(klass, Class)
        (used[item[item[:type]].object_id] ||= Set.new) << used_value if [:extend, :include].include?(item[:type])
      end
    end

    require 'fileutils'
    FileUtils.mkdir_p(output_dir)

    grouped.each do |gem, klass_ids|
      File.open("#{File.join(output_dir, gem[:gem])}.rbi", 'w') do |f|
        f.write("# AUTOGENERATED GEM RBI\n")
        f.write("# Run `srb init` to regenerate this file\n")
        f.write("# #{gem[:gem]}-#{gem[:version]}\n")
        f.write("# typed: true\n")
        klass_ids.each do |klass_id, defined|
          klass = ObjectSpace._id2ref(klass_id)

          next if !((SorbetRBIGeneration::Module.real_is_a?(klass, Module) && !SorbetRBIGeneration::Module.real_name(klass).nil?) || used?(klass_id, used))
          next if SorbetRBIGeneration::Module.real_is_a?(klass, Class) && klass.superclass == Delegator && !klass.name

          # next if [Object, BasicObject, Hash].include?(klass) # TODO should this be here?

          f.write("#{SorbetRBIGeneration::Module.real_is_a?(klass, Class) ? 'class' : 'module'} #{class_name(klass)}")
          f.write(" < #{class_name(klass.superclass)}") if SorbetRBIGeneration::Module.real_is_a?(klass, Class) && ![Object, nil].include?(klass.superclass)
          f.write("\n")

          rows = defined.map do |item|
            case item[:type]
            when :method
              if !valid_method_name?(item[:method])
                warn("Invalid method name: #{klass}.#{item[:method]}")
                next
              end
              if BAD_METHODS.include?([gem[:gem], class_name(klass), item[:method]])
                next
              end
              begin
                method = item[:singleton] ? klass.method(item[:method]) : klass.instance_method(item[:method])
                "#{generate_method(method, !item[:singleton])}"
              rescue NameError
              end
            when :include, :extend
              name = class_name(item[item[:type]])
              "  #{item[:type]} #{name}"
            end
          end
          rows = rows.compact.sort
          f.write(rows.join("\n"))
          f.write("\n") if !rows.empty?
          f.write("end\n")
        end
      end
    end
  end

  private

  def generate_method(method, instance, spaces = 2)
    # method.parameters is an array of:
    # a      [:req, :a]
    # b = 1  [:opt, :b]
    # c:     [:keyreq, :c]
    # d: 1   [:key, :d]
    # *e     [:rest, :e]
    # **f    [:keyrest, :f]
    # &g     [:block, :g]
    prefix = ' ' * spaces
    parameters = method.parameters.map.with_index do |(type, name), index|
      name = "arg#{index}" if name.nil? || name.empty?
      case type
      when :req
        name
      when :opt
        "#{name} = nil"
      when :keyreq
        "#{name}:"
      when :key
        "#{name}: nil"
      when :rest
        "*#{name}"
      when :keyrest
        "**#{name}"
      when :block
        "&#{name}"
      else
        raise "Unknown parameter type: #{type}"
      end
    end
    parameters = parameters.join(', ')
    parameters = "(#{parameters})" unless parameters.empty?
    "#{prefix}def #{instance ? '' : 'self.'}#{method.name}#{parameters}; end"
  end

  def anonymous_id
    @prev_anonymous_id += 1
  end

  def gem_from_location(location)
    match =
      location&.match(/^.*\/(ruby)\/([\d.]+)\//) || # ruby stdlib
      location&.match(/^.*\/(site_ruby)\/([\d.]+)\//) || # rubygems
      location&.match(/^.*\/gems\/[\d.]+(?:\/bundler)?\/gems\/([^\/]+)-([^-\/]+)\//i) # gem
    if match.nil?
      # uncomment to generate files for methods outside of gems
      # {
      #   path: location,
      #   gem: location.gsub(/[\/\.]/, '_'),
      #   version: '1.0.0',
      # }
      nil
    else
      {
        path: match[0],
        gem: match[1],
        version: match[2],
      }
    end
  end

  def class_name(klass)
    klass = @delegate_classes[SorbetRBIGeneration::Module.real_object_id(klass)] || klass
    name = SorbetRBIGeneration::Module.real_name(klass) if SorbetRBIGeneration::Module.real_is_a?(klass, Module)

    # class/module has no name; it must be anonymous
    if name.nil? || name == ""
      middle = SorbetRBIGeneration::Module.real_is_a?(klass, Class) ? klass.superclass : klass.class
      id = @anonymous_map[SorbetRBIGeneration::Module.real_object_id(klass)] ||= anonymous_id
      return "Anonymous_#{class_name(middle).gsub('::', '_')}_#{id}"
    end

    # if the name doesn't only contain word characters and ':', or any part doesn't start with a capital, Sorbet doesn't support it
    if name !~ /^[\w:]+$/ || !name.split('::').all? { |part| part =~ /^[A-Z]/ }
      warn("Invalid class name: #{name}")
      id = @anonymous_map[SorbetRBIGeneration::Module.real_object_id(klass)] ||= anonymous_id
      return "InvalidName_#{name.gsub(/[^\w]/, '_').gsub(/0x([0-9a-f]+)/, '0x00')}_#{id}"
    end

    name
  end

  def used?(klass, used)
    used_by = used[klass] || []
    used_by.any? { |user| user == true || used?(user, used) }
  end

  def valid_method_name?(symbol)
    string = symbol.to_s
    return true if SPECIAL_METHOD_NAMES.include?(string)
    string =~ /^[[:word:]]+[?!=]?$/
  end
end

# TODO switch the Struct handling to:
#
# class Subclass < Struct(:key1, :key2)
# end
#
# generating:
#
# TemporaryStruct = Struct(:key1, :key2)
# class Subclass < TemporaryStruct
# end
#
# instead of manually defining every getter/setter

class SorbetRBIGeneration::RbiGenerator
  def self.main(output_dir = './rbi/gems/')
    trace_results = SorbetRBIGeneration::Tracer.trace do
      SorbetRBIGeneration::RequireEverything.require_everything
    end

    FileUtils.rm_r(output_dir) if Dir.exist?(output_dir)
    SorbetRBIGeneration::RbiSerializer.new(trace_results).serialize(output_dir)
  end
end

if $PROGRAM_NAME == __FILE__
  SorbetRBIGeneration::RbiGenerator.main
end

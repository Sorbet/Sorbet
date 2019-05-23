# frozen_string_literal: true
# typed: true

require_relative './gem_loader'

class ExitCalledError < RuntimeError
end

class Sorbet::Private::RequireEverything
  # Goes through the most common ways to require all your userland code
  def self.require_everything(pause_tracepoints = -> (&blk) {blk.call})
    patch_kernel
    load_rails
    load_bundler(pause_tracepoints) # this comes second since some rails projects fail `Bundler.require' before rails is loaded
    require_all_files
  end

  def self.load_rails
    return unless rails?
    require './config/application'
    rails = Object.const_get(:Rails)
    rails.application.require_environment!
    rails.application.eager_load!
    true
  end

  def self.load_bundler(pause_tracepoints)
    return unless File.exist?('Gemfile')
    return unless pause_tracepoints.call do
      begin
        require 'bundler'
        true
      rescue LoadError
        false
      end
    end
    Sorbet::Private::GemLoader.require_all_gems
  end

  def self.require_all_files
    excluded_paths = Set.new
    excluded_paths += excluded_rails_files if rails?

    abs_paths = Dir.glob("#{Dir.pwd}/**/*.rb")
    errors = []
    abs_paths.each_with_index do |abs_path, i|
      # Executable files are likely not meant to be required.
      # Some things we're trying to prevent against:
      # - misbehaving require-time side effects (removing files, reading from stdin, etc.)
      # - extra long runtime (making network requests, running a benchmark)
      # While this isn't a perfect heuristic for these things, it's pretty good.
      next if File.executable?(abs_path)
      next if excluded_paths.include?(abs_path)

      begin
        my_require(abs_path, i+1, abs_paths.size)
      rescue LoadError, NoMethodError, SyntaxError
        next
      rescue
        errors << abs_path
        next
      end
    end
    # one more chance for order dependent things
    errors.each_with_index do |abs_path, i|
      begin
        my_require(abs_path, i+1, errors.size)
      rescue
      end
    end
    puts
  end

  def self.my_require(path, numerator, denominator)
    print "\r[#{numerator}/#{denominator}] require_relative #{path}"
    require_relative path
  end

  def self.patch_kernel
    Kernel.send(:define_method, :exit) do |*|
      puts 'Kernel#exit was called while requiring ruby source files'
      raise ExitCalledError.new
    end

    Kernel.send(:define_method, :at_exit) do |&block|
      if File.split($0).last == 'rake'
        # Let `rake test` work
        super
        return proc {}
      end
      puts "Ignoring at_exit: #{block}"
      proc {}
    end
  end

  private

  def self.excluded_rails_files
    excluded_paths = Set.new

    # Exclude files that have already been loaded by rails
    rails = Object.const_get(:Rails)
    load_paths = rails.application.send(:_all_load_paths)
    load_paths.each do |path|
      excluded_paths += Dir.glob("#{Dir.pwd}/#{path}/**/*.rb")
    end

    # Exclude initializers, as they have already been run by rails and
    # can contain side-effects like monkey-patching that should
    # only be run once.
    excluded_paths += Dir.glob("#{Dir.pwd}/config/initializers/**/*.rb")
  end

  def self.rails?
    return false unless File.exist?('config/application.rb')
    begin
      require 'rails'
    rescue LoadError
      return false
    end
    true
  end
end

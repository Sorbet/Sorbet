# frozen_string_literal: true
# typed: ignore

require 'minitest/autorun'
require 'minitest/spec'
require 'mocha/minitest'

require 'tmpdir'

class Sorbet; end
module Sorbet::Private; end
module Sorbet::Private::HiddenMethodFinder; end
module Sorbet::Private::HiddenMethodFinder::Test; end

class Sorbet::Private::HiddenMethodFinder::Test::Simple < MiniTest::Spec
  it 'works on a simple example' do

    Dir.mktmpdir do |dir|
      FileUtils.cp_r(__dir__ + '/simple/', dir)
      FileUtils.cp_r(__dir__ + '/sorbet/', dir)
      olddir = __dir__
      Dir.chdir dir

      IO.popen(
        olddir + '/../../lib/hidden-definition-finder.rb'
      ) {|io| io.read}

      assert_equal(true, $?.success?)
      # Some day these can be snapshot tests, but this isn't stable enough for
      # that yet
      # assert_equal(File.read(olddir + '/simple.errors.txt'), File.read('rbi/hidden-definitions/errors.txt'))
      # assert_equal(File.read(olddir + '/simple.hidden.rbi'), File.read('rbi/hidden-definitions/hidden.rbi'))
      assert_match("class Foo\n  def bar()", File.read('sorbet/rbi/hidden-definitions/hidden.rbi'))
      refute_match("ClassOverride", File.read('sorbet/rbi/hidden-definitions/hidden.rbi'))
    end
  end
end
